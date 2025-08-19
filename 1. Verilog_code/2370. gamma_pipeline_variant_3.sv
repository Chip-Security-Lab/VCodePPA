//SystemVerilog
module gamma_pipeline (
    input wire clk,
    input wire [7:0] in,
    output reg [7:0] out
);
    // 优化后的流水线寄存器 - 从3级减少到2级
    reg [7:0] pipe_stage1_processed;
    
    // 阶段1: 合并线性缩放和偏移调整 - 将输入值乘以2并减去偏移值
    always @(posedge clk) begin
        pipe_stage1_processed <= (in << 1) - 15;
    end
    
    // 阶段2: 最终缩放 - 右移一位(除以2)并输出
    always @(posedge clk) begin
        out <= pipe_stage1_processed >> 1;
    end
    
endmodule