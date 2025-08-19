//SystemVerilog
module base64_encoder (
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    input wire [7:0] data_in,
    output reg [5:0] base64_out,
    output reg valid_out
);
    localparam IDLE = 2'b00, PROC1 = 2'b01, PROC2 = 2'b10, PROC3 = 2'b11;
    
    reg [1:0] state, next_state;
    reg [15:0] buffer, next_buffer;
    reg [1:0] out_count, next_out_count;
    reg [5:0] next_base64_out;
    reg next_valid_out;

    // Next state logic
    always @* begin
        next_state = state;
        next_buffer = buffer;
        next_out_count = out_count;
        next_base64_out = base64_out;
        next_valid_out = 1'b0;

        case (state)
            IDLE: begin
                if (data_valid) begin
                    next_buffer = {data_in, buffer[7:0]};
                    next_state = PROC1;
                    next_out_count = 2'b00;
                end
                next_valid_out = 1'b0;
            end
            PROC1: begin
                next_base64_out = buffer[15:10];
                next_valid_out = 1'b1;
                next_out_count = out_count + 1'b1;
                if (out_count == 2'b10)
                    next_state = IDLE;
                else
                    next_state = PROC2;
            end
            PROC2: begin
                next_base64_out = buffer[9:4];
                next_valid_out = 1'b1;
                next_out_count = out_count + 1'b1;
                if (out_count == 2'b10)
                    next_state = IDLE;
                else
                    next_state = PROC3;
            end
            PROC3: begin
                next_base64_out = {buffer[3:0], 2'b00};
                next_valid_out = 1'b1;
                next_out_count = out_count + 1'b1;
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
                next_valid_out = 1'b0;
            end
        endcase
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            buffer <= 16'b0;
            out_count <= 2'b00;
            base64_out <= 6'b0;
            valid_out <= 1'b0;
        end else begin
            state <= next_state;
            buffer <= next_buffer;
            out_count <= next_out_count;
            base64_out <= next_base64_out;
            valid_out <= next_valid_out;
        end
    end
endmodule