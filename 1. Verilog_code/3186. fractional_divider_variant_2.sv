//SystemVerilog
module fractional_divider #(
    parameter ACC_WIDTH = 8,
    parameter STEP = 85  // 1.6分频示例值（STEP = 256 * 5/8）
)(
    input clk,
    input rst,
    output reg clk_out
);

// 相位累加器寄存器
reg [ACC_WIDTH-1:0] phase_acc_stage1;
reg [ACC_WIDTH-1:0] phase_acc_stage2;
reg [ACC_WIDTH-1:0] phase_acc_stage3;

// 时钟输出寄存器
reg clk_out_stage1;
reg clk_out_stage2;

// 有效信号控制寄存器
reg valid_stage1;
reg valid_stage2;
reg valid_stage3;

// 重置控制块
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // 阶段1寄存器复位
        phase_acc_stage1 <= 0;
        valid_stage1 <= 0;
        
        // 阶段2寄存器复位
        phase_acc_stage2 <= 0;
        clk_out_stage1 <= 0;
        valid_stage2 <= 0;
        
        // 阶段3寄存器复位
        phase_acc_stage3 <= 0;
        clk_out_stage2 <= 0;
        clk_out <= 0;
        valid_stage3 <= 0;
    end
end

// 阶段1: 相位累加计算
always @(posedge clk) begin
    if (!rst) begin
        phase_acc_stage1 <= phase_acc_stage3 + STEP;
        valid_stage1 <= 1'b1;
    end
end

// 阶段2: MSB检测与传递
always @(posedge clk) begin
    if (!rst) begin
        phase_acc_stage2 <= phase_acc_stage1;
        clk_out_stage1 <= phase_acc_stage1[ACC_WIDTH-1];
        valid_stage2 <= valid_stage1;
    end
end

// 阶段3: 输出生成
always @(posedge clk) begin
    if (!rst) begin
        phase_acc_stage3 <= phase_acc_stage2;
        clk_out_stage2 <= clk_out_stage1;
        valid_stage3 <= valid_stage2;
    end
end

// 最终时钟输出生成
always @(posedge clk) begin
    if (!rst) begin
        clk_out <= clk_out_stage2;
    end
end

endmodule