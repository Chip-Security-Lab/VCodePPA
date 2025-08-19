module Div5(input clk, [15:0] a, b, output reg [15:0] res);
    reg [15:0] stage1, stage2, stage3;
    always @(posedge clk) begin
        stage1 <= a / b;
        stage2 <= stage1;
        stage3 <= stage2;
        res <= stage3;
    end
endmodule