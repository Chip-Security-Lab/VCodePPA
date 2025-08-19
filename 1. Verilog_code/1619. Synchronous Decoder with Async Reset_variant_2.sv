//SystemVerilog
module sync_decoder_async_reset (
    input clk,
    input arst_n,
    input valid,
    input [2:0] address,
    output reg ready,
    output reg [7:0] cs_n
);
    reg [7:0] next_cs_n;
    reg [7:0] cs_n_buf1;
    reg [7:0] cs_n_buf2;
    
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            cs_n <= 8'hFF;
            cs_n_buf1 <= 8'hFF;
            cs_n_buf2 <= 8'hFF;
            ready <= 1'b0;
        end else begin
            if (valid) begin
                case (address)
                    3'd0: next_cs_n = 8'b11111110;
                    3'd1: next_cs_n = 8'b11111101;
                    3'd2: next_cs_n = 8'b11111011;
                    3'd3: next_cs_n = 8'b11110111;
                    3'd4: next_cs_n = 8'b11101111;
                    3'd5: next_cs_n = 8'b11011111;
                    3'd6: next_cs_n = 8'b10111111;
                    3'd7: next_cs_n = 8'b01111111;
                    default: next_cs_n = 8'hFF;
                endcase
                cs_n_buf1 <= next_cs_n;
                cs_n_buf2 <= cs_n_buf1;
                cs_n <= cs_n_buf2;
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end
endmodule