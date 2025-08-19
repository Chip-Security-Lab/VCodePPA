//SystemVerilog
module AsyncNor(input clk, rst, a, b, output reg y);
    reg a_reg, b_reg;
    
    always @(posedge clk, posedge rst) begin
        a_reg <= rst ? 1'b0 : a;
        b_reg <= rst ? 1'b0 : b;
        y <= rst ? 1'b0 : ~(a_reg | b_reg);
    end
endmodule