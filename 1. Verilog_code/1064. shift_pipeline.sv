module shift_pipeline #(parameter WIDTH=8, STAGES=3) (
    input clk,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
// 使用单独的寄存器替代数组
reg [WIDTH-1:0] pipe0;
reg [WIDTH-1:0] pipe1;
reg [WIDTH-1:0] pipe2;
// 支持最多3级流水线，需要时可扩展

always @(posedge clk) begin
    pipe0 <= din << 1;
    if (STAGES > 1) pipe1 <= pipe0 << 1;
    if (STAGES > 2) pipe2 <= pipe1 << 1;
end

// 根据STAGES参数选择输出
assign dout = (STAGES == 1) ? pipe0 :
             (STAGES == 2) ? pipe1 : pipe2;
endmodule