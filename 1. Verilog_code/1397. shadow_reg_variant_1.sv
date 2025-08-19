//SystemVerilog
module shadow_reg #(parameter DW=16) (
    input clk, en, commit,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    // 输入级流水线寄存器
    reg [DW-1:0] din_stage1;
    reg [DW-1:0] din_stage2;
    
    // 控制信号流水线寄存器
    reg en_stage1, en_stage2;
    reg commit_stage1, commit_stage2, commit_stage3;
    
    // 数据寄存器
    reg [DW-1:0] working_reg_stage1, working_reg_stage2;
    reg [DW-1:0] shadow_reg_stage1, shadow_reg_stage2;
    
    // 第一级流水线 - 输入寄存和控制信号
    always @(posedge clk) begin
        din_stage1 <= din;
        en_stage1 <= en;
        commit_stage1 <= commit;
    end
    
    // 第二级流水线 - 继续传递数据和控制信号
    always @(posedge clk) begin
        din_stage2 <= din_stage1;
        en_stage2 <= en_stage1;
        commit_stage2 <= commit_stage1;
    end
    
    // 第三级流水线 - 传递提交信号到最后阶段
    always @(posedge clk) begin
        commit_stage3 <= commit_stage2;
    end
    
    // 工作寄存器流水线 - 第一级
    always @(posedge clk) begin
        if(en_stage2) working_reg_stage1 <= din_stage2;
    end
    
    // 工作寄存器流水线 - 第二级
    always @(posedge clk) begin
        working_reg_stage2 <= working_reg_stage1;
    end
    
    // 影子寄存器流水线 - 第一级
    always @(posedge clk) begin
        if(commit_stage3) shadow_reg_stage1 <= working_reg_stage2;
    end
    
    // 影子寄存器流水线 - 第二级(输出阶段)
    always @(posedge clk) begin
        shadow_reg_stage2 <= shadow_reg_stage1;
    end
    
    // 输出赋值
    assign dout = shadow_reg_stage2;
endmodule