//SystemVerilog
module and_nand_xnor_gate (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号
    input wire A, B, C, D,  // 输入信号
    output reg Y            // 输出信号
);

    // 内部信号声明 - 分割数据路径
    reg stage1_AB;          // 第一阶段: A & B 结果
    reg stage1_CD;          // 第一阶段: C & D 结果
    reg stage1_A;           // 第一阶段: A 寄存器
    
    reg stage2_NAND_CD;     // 第二阶段: ~(C & D) 结果
    reg stage2_AB;          // 第二阶段: (A & B) 寄存器
    reg stage2_A;           // 第二阶段: A 寄存器
    
    reg stage3_AB_NAND_CD;  // 第三阶段: (A & B) & ~(C & D) 结果
    reg stage3_A;           // 第三阶段: A 寄存器

    // 第一流水线阶段 - 拆分为多个小型always块
    // Stage 1 - A & B 计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_AB <= 1'b0;
        else
            stage1_AB <= A & B;
    end
    
    // Stage 1 - C & D 计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_CD <= 1'b0;
        else
            stage1_CD <= C & D;
    end
    
    // Stage 1 - 保存输入A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_A <= 1'b0;
        else
            stage1_A <= A;
    end
    
    // 第二流水线阶段 - 拆分为多个小型always块
    // Stage 2 - NAND CD 计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_NAND_CD <= 1'b0;
        else
            stage2_NAND_CD <= ~stage1_CD;
    end
    
    // Stage 2 - 传递 A & B
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_AB <= 1'b0;
        else
            stage2_AB <= stage1_AB;
    end
    
    // Stage 2 - 传递输入A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_A <= 1'b0;
        else
            stage2_A <= stage1_A;
    end
    
    // 第三流水线阶段 - 拆分为多个小型always块
    // Stage 3 - AB & NAND_CD 计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_AB_NAND_CD <= 1'b0;
        else
            stage3_AB_NAND_CD <= stage2_AB & stage2_NAND_CD;
    end
    
    // Stage 3 - 传递输入A
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_A <= 1'b0;
        else
            stage3_A <= stage2_A;
    end
    
    // 最终输出阶段 - XNOR操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Y <= 1'b0;
        else
            Y <= ~(stage3_AB_NAND_CD ^ stage3_A);
    end

endmodule