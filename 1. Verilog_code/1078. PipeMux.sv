module PipeMux #(parameter DW=8, STAGES=2) (
    input clk, rst,
    input [3:0] sel,
    input [(16*DW)-1:0] din, // 改为一维数组
    output [DW-1:0] dout
);
// 使用单独的寄存器替代数组
reg [DW-1:0] pipe0;
reg [DW-1:0] pipe1;
// 支持最多2级流水线，需要时可扩展

always @(posedge clk) begin
    if(rst) begin
        pipe0 <= {DW{1'b0}};
        if (STAGES > 1) pipe1 <= {DW{1'b0}};
    end else begin
        pipe0 <= din[(sel*DW) +: DW]; // 使用位选择操作符
        if (STAGES > 1) pipe1 <= pipe0;
    end
end

// 根据STAGES参数选择输出
assign dout = (STAGES <= 1) ? pipe0 : pipe1;
endmodule