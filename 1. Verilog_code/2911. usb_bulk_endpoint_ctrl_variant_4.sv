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
    // IEEE 1364-2005 Verilog standard
    
    // FSM states
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // Stage 1 registers (Command decoding and state tracking)
    reg [1:0] state_stage1, next_state_stage1;
    reg token_received_stage1;
    reg [3:0] endpoint_stage1;
    reg data_valid_in_stage1;
    reg [7:0] data_in_stage1;
    
    // Stage 2 registers (Buffer management)
    reg [1:0] state_stage2;
    reg [$clog2(BUFFER_DEPTH)-1:0] write_ptr_stage2, read_ptr_stage2;
    reg [$clog2(BUFFER_DEPTH):0] count_stage2;
    reg data_valid_stage2;
    reg [7:0] data_stage2;
    reg buffer_write_en_stage2;
    reg buffer_read_en_stage2;
    
    // Stage 3 registers (Output processing)
    reg [1:0] state_stage3;
    reg [7:0] data_out_stage3;
    reg data_valid_out_stage3;
    reg buffer_full_stage3;
    reg buffer_empty_stage3;
    reg [1:0] response_stage3;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // Buffer memory
    reg [7:0] buffer [0:BUFFER_DEPTH-1];
    
    // Optimized buffer status signals
    wire is_buffer_full = (count_stage2 == BUFFER_DEPTH);
    wire is_buffer_empty = (count_stage2 == 0);
    wire can_write = !is_buffer_full && (state_stage1 == RX);
    wire can_read = !is_buffer_empty && (state_stage1 == TX);
    wire endpoint_match = (endpoint_i == state_stage1);
    
    // Stage 1: Command decoding and state management
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage1 <= IDLE;
            token_received_stage1 <= 1'b0;
            endpoint_stage1 <= 4'b0;
            data_valid_in_stage1 <= 1'b0;
            data_in_stage1 <= 8'b0;
            stage1_valid <= 1'b0;
        end else begin
            state_stage1 <= next_state_stage1;
            token_received_stage1 <= token_received_i;
            endpoint_stage1 <= endpoint_i;
            data_valid_in_stage1 <= data_valid_i;
            data_in_stage1 <= data_i;
            stage1_valid <= 1'b1;
        end
    end
    
    // Optimized state transition logic
    always @(*) begin
        next_state_stage1 = state_stage1;
        
        if (token_received_i) begin
            case (state_stage1)
                IDLE: begin
                    next_state_stage1 = endpoint_i[3] ? TX : RX;
                end
                
                default: begin  // RX, TX, STALL
                    if (!endpoint_match) 
                        next_state_stage1 = IDLE;
                end
            endcase
        end
    end
    
    // Stage 2: Buffer management 
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage2 <= IDLE;
            write_ptr_stage2 <= 0;
            read_ptr_stage2 <= 0;
            count_stage2 <= 0;
            data_valid_stage2 <= 1'b0;
            data_stage2 <= 8'b0;
            buffer_write_en_stage2 <= 1'b0;
            buffer_read_en_stage2 <= 1'b0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            state_stage2 <= state_stage1;
            data_valid_stage2 <= data_valid_in_stage1;
            data_stage2 <= data_in_stage1;
            
            // Optimized buffer write logic
            buffer_write_en_stage2 <= data_valid_in_stage1 && can_write;
            
            // Optimized buffer read logic
            buffer_read_en_stage2 <= can_read;
            
            // Update pointers and count - optimized logic
            if (buffer_write_en_stage2) begin
                buffer[write_ptr_stage2] <= data_in_stage1;
                write_ptr_stage2 <= (write_ptr_stage2 + 1) % BUFFER_DEPTH;
                count_stage2 <= count_stage2 + 1'b1;
            end else if (buffer_read_en_stage2) begin
                read_ptr_stage2 <= (read_ptr_stage2 + 1) % BUFFER_DEPTH;
                count_stage2 <= count_stage2 - 1'b1;
            end
            
            stage2_valid <= stage1_valid;
        end
    end
    
    // Optimized response generation based on state
    function [1:0] get_response;
        input [1:0] state;
        input buffer_full;
        input buffer_empty;
        begin
            case (state)
                RX:     get_response = buffer_full ? 2'b00 : 2'b01; // NAK if full, ACK otherwise
                TX:     get_response = buffer_empty ? 2'b00 : 2'b01; // NAK if empty, DATA otherwise
                STALL:  get_response = 2'b10; // Always STALL
                default: get_response = 2'b00; // IDLE: always NAK
            endcase
        end
    endfunction
    
    // Stage 3: Output generation
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_stage3 <= IDLE;
            data_out_stage3 <= 8'b0;
            data_valid_out_stage3 <= 1'b0;
            buffer_full_stage3 <= 1'b0;
            buffer_empty_stage3 <= 1'b1;
            response_stage3 <= 2'b00;
            stage3_valid <= 1'b0;
        end else if (stage2_valid) begin
            state_stage3 <= state_stage2;
            
            // Generate output data and control signals - read ahead for better timing
            data_out_stage3 <= buffer_read_en_stage2 ? buffer[read_ptr_stage2] : data_out_stage3;
            data_valid_out_stage3 <= buffer_read_en_stage2;
            
            // Update buffer status
            buffer_full_stage3 <= is_buffer_full;
            buffer_empty_stage3 <= is_buffer_empty;
            
            // Use optimized response function
            response_stage3 <= get_response(state_stage2, is_buffer_full, is_buffer_empty);
            
            stage3_valid <= stage2_valid;
        end
    end
    
    // Output assignment - flattened for better timing
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            data_o <= 8'b0;
            data_valid_o <= 1'b0;
            buffer_full_o <= 1'b0;
            buffer_empty_o <= 1'b1;
            response_o <= 2'b00;
        end else if (stage3_valid) begin
            {data_o, data_valid_o, buffer_full_o, buffer_empty_o, response_o} <= 
            {data_out_stage3, data_valid_out_stage3, buffer_full_stage3, buffer_empty_stage3, response_stage3};
        end
    end
    
endmodule