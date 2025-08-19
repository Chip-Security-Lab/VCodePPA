//SystemVerilog
module Multiplier3(
    input clk,
    input [3:0] data_a, data_b,
    input req,
    output reg ack,
    output reg [7:0] mul_result
);
    reg [7:0] result_reg;
    reg ack_reg;
    reg [7:0] mul_result_reg;
    
    always @(posedge clk) begin
        if (req) begin
            result_reg <= data_a * data_b;
            ack_reg <= 1'b1;
            mul_result_reg <= data_a * data_b;
        end else begin
            ack_reg <= 1'b0;
        end
    end
    
    always @(posedge clk) begin
        mul_result <= mul_result_reg;
    end
    
    assign ack = ack_reg;
endmodule