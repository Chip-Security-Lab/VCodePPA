module pipelined_ashift (
    input clk, rst,
    input [31:0] din,
    input [4:0] shift,
    output reg [31:0] dout
);
reg [31:0] stage1, stage2;
always @(posedge clk) begin
    if (rst) {stage1, stage2, dout} <= 0;
    else begin
        stage1 <= din >>> (shift[4:3] * 8);    // 处理高2位
        stage2 <= stage1 >>> (shift[2:1] * 2); // 处理中间2位
        dout <= stage2 >>> shift[0];           // 处理最后1位
    end
end
endmodule