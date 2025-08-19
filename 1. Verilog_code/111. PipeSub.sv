module PipeSub(input clk, [15:0] a,b, output reg [15:0] res);
    reg [15:0] s1,s2;
    always @(posedge clk) begin
        s1 <= a - b;
        res <= s1;
    end
endmodule