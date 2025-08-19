//SystemVerilog
module usb_bulk_endpoint_ctrl #(
    parameter MAX_PACKET_SIZE = 64,
    parameter BUFFER_DEPTH = 8
)(
    input wire clk_i, rst_n_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    input wire token_received_i,
    input wire [3:0] endpoint_i,
    output reg [7:0] data_o,
    output reg data_valid_o,
    output reg buffer_full_o,
    output reg buffer_empty_o,
    output reg [1:0] response_o
);
    // FSM states
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // Registers
    reg [1:0] state_r, next_state;
    reg [$clog2(BUFFER_DEPTH)-1:0] write_ptr, read_ptr;
    reg [$clog2(BUFFER_DEPTH):0] count;
    reg [7:0] buffer [0:BUFFER_DEPTH-1];
    
    // Pipeline registers for critical paths
    reg token_received_pipe;
    reg [3:0] endpoint_pipe;
    reg data_valid_pipe;
    reg [$clog2(BUFFER_DEPTH):0] count_pipe;
    reg buffer_empty_pipe;
    reg buffer_full_pipe;
    reg [1:0] state_pipe;
    
    // Pipeline stage 1: Input registration
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            token_received_pipe <= 1'b0;
            endpoint_pipe <= 4'h0;
            data_valid_pipe <= 1'b0;
            count_pipe <= 0;
            buffer_empty_pipe <= 1'b1;
            buffer_full_pipe <= 1'b0;
            state_pipe <= IDLE;
        end else begin
            token_received_pipe <= token_received_i;
            endpoint_pipe <= endpoint_i;
            data_valid_pipe <= data_valid_i;
            count_pipe <= count;
            buffer_empty_pipe <= buffer_empty_o;
            buffer_full_pipe <= buffer_full_o;
            state_pipe <= state_r;
        end
    end
    
    // State register update logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= IDLE;
        end else begin
            state_r <= next_state;
        end
    end
    
    // Pipelined state transition logic
    always @(*) begin
        next_state = state_pipe;
        case (state_pipe)
            IDLE: begin
                if (token_received_pipe) begin
                    if (endpoint_pipe == 4'h1) 
                        next_state = RX;
                    else if (endpoint_pipe == 4'h2)
                        next_state = TX;
                    else
                        next_state = IDLE;
                end
            end
            RX: begin
                if (!data_valid_pipe && count_pipe > 0)
                    next_state = IDLE;
            end
            TX: begin
                if (buffer_empty_pipe)
                    next_state = IDLE;
            end
            STALL: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Data write logic with pipelined control
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            write_ptr <= 0;
        end else if (data_valid_pipe && !buffer_full_pipe && state_pipe == RX) begin
            buffer[write_ptr] <= data_i;
            write_ptr <= (write_ptr == BUFFER_DEPTH-1) ? 0 : write_ptr + 1;
        end
    end
    
    // Data read logic with pipelined control
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            read_ptr <= 0;
            data_o <= 8'h00;
            data_valid_o <= 1'b0;
        end else if (state_pipe == TX && !buffer_empty_pipe) begin
            data_o <= buffer[read_ptr];
            data_valid_o <= 1'b1;
            read_ptr <= (read_ptr == BUFFER_DEPTH-1) ? 0 : read_ptr + 1;
        end else begin
            data_valid_o <= 1'b0;
        end
    end
    
    // Split the complex counter logic into two pipeline stages
    // Stage 1: Calculate conditions
    reg write_enable, read_enable;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            write_enable <= 1'b0;
            read_enable <= 1'b0;
        end else begin
            write_enable <= data_valid_pipe && !buffer_full_pipe && state_pipe == RX;
            read_enable <= state_pipe == TX && !buffer_empty_pipe;
        end
    end
    
    // Stage 2: Update counter based on pipelined conditions
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            count <= 0;
        end else if (write_enable && !read_enable) begin
            // Only write
            count <= count + 1;
        end else if (!write_enable && read_enable) begin
            // Only read
            count <= count - 1;
        end
        // Both read and write or neither: count remains unchanged
    end
    
    // Buffer status flags with pipelined count evaluation
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            buffer_full_o <= 1'b0;
            buffer_empty_o <= 1'b1;
        end else begin
            buffer_full_o <= (count == BUFFER_DEPTH);
            buffer_empty_o <= (count == 0);
        end
    end
    
    // Response logic with pipelined state
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            response_o <= 2'b00;
        end else begin
            case (state_pipe)
                IDLE: response_o <= 2'b00;
                RX: response_o <= 2'b01;
                TX: response_o <= 2'b10;
                STALL: response_o <= 2'b11;
                default: response_o <= 2'b00;
            endcase
        end
    end
    
endmodule