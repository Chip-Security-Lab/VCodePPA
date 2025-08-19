//SystemVerilog
module multiphase_clock(
    input wire sys_clk,
    input wire rst,
    
    // Valid-Ready 接口
    output wire valid,
    input wire ready,
    output wire [7:0] phase_clks
);
    // 流水线寄存器
    reg [7:0] shift_reg_stage1;
    reg [7:0] shift_reg_stage2;
    reg [7:0] shift_reg_stage3;
    
    // 流水线阶段有效信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 流水线阶段控制信号
    wire stage1_enable, stage2_enable, stage3_enable;
    
    // 确定各阶段是否可以前进
    assign stage3_enable = valid_stage3 & ready;
    assign stage2_enable = valid_stage2 & (~valid_stage3 | ready);
    assign stage1_enable = ~valid_stage2 | stage2_enable;
    
    // 流水线第一级 - 生成移位寄存器
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg_stage1 <= 8'b00000001;
            valid_stage1 <= 1'b0;
        end else if (stage1_enable) begin
            shift_reg_stage1 <= {shift_reg_stage3[6:0], shift_reg_stage3[7]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // 流水线第二级 - 中间处理
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg_stage2 <= 8'b00000000;
            valid_stage2 <= 1'b0;
        end else if (stage2_enable) begin
            shift_reg_stage2 <= shift_reg_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级 - 输出处理
    always @(posedge sys_clk or posedge rst) begin
        if (rst) begin
            shift_reg_stage3 <= 8'b00000000;
            valid_stage3 <= 1'b0;
        end else if (stage3_enable) begin
            shift_reg_stage3 <= shift_reg_stage2;
            valid_stage3 <= valid_stage2;
        end else if (ready && valid_stage3) begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // 输出赋值
    assign phase_clks = shift_reg_stage3;
    assign valid = valid_stage3;
    
endmodule