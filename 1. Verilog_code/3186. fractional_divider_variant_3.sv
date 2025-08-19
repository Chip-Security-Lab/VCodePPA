//SystemVerilog
module fractional_divider #(
    parameter ACC_WIDTH = 8,
    parameter STEP = 85  // 1.6分频示例值（STEP = 256 * 5/8）
)(
    input  logic clk,
    input  logic rst,
    output logic clk_out
);
    // 定义流水线阶段寄存器和信号
    logic [ACC_WIDTH-1:0] phase_acc_stage1;
    logic [ACC_WIDTH-1:0] phase_acc_stage2;
    logic [ACC_WIDTH-1:0] next_acc_stage1;
    logic [ACC_WIDTH-1:0] next_acc_stage2;
    logic carry_stage1;
    logic carry_stage2;
    logic valid_stage1;
    logic valid_stage2;

    // 第一级流水线：计算累加和进位
    always_comb begin
        {carry_stage1, next_acc_stage1} = phase_acc_stage2 + STEP;
    end

    // 流水线寄存器和控制逻辑
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 重置所有流水线寄存器
            phase_acc_stage1 <= '0;
            phase_acc_stage2 <= '0;
            carry_stage2 <= 1'b0;
            next_acc_stage2 <= '0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // 第一级流水线寄存器更新
            valid_stage1 <= 1'b1;  // 流水线启动后始终有效
            next_acc_stage2 <= next_acc_stage1;
            carry_stage2 <= carry_stage1;
            
            // 第二级流水线寄存器更新
            valid_stage2 <= valid_stage1;
            phase_acc_stage2 <= valid_stage1 ? next_acc_stage2 : phase_acc_stage2;
            
            // 输出寄存器更新
            clk_out <= valid_stage2 ? carry_stage2 : clk_out;
        end
    end
endmodule