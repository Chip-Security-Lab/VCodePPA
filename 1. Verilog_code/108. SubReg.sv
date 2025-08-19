module SubReg(input clk,rst, [3:0] i1,i2, output reg [3:0] o);
    always @(posedge clk or posedge rst) 
        o <= rst ? 0 : i1 - i2;
endmodule