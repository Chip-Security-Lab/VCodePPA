//SystemVerilog
module Multiplier5(
    input clk,
    input [7:0] in_a, in_b,
    input req,
    output reg ack,
    output reg [15:0] out
);
    reg [7:0] a_reg, b_reg;
    reg req_reg;
    reg [15:0] product;
    
    always @(posedge clk) begin
        req_reg <= req;
        
        if(req) begin
            a_reg <= in_a;
            b_reg <= in_b;
        end
        
        product <= a_reg * b_reg;
        
        if(req_reg) begin
            out <= product;
            ack <= 1'b1;
        end else begin
            ack <= 1'b0;
        end
    end
endmodule