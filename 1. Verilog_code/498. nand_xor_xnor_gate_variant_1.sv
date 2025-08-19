//SystemVerilog
//IEEE 1364-2005 Verilog标准
module nand_xor_xnor_gate (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 复位信号，低电平有效
    input wire A, B, C,   // 输入A, B, C
    output reg Y          // 输出Y，寄存器输出
);
    // 内部信号声明 - 更细粒度分解数据路径
    reg stage1_A_reg, stage1_B_reg, stage1_C_reg;  // 第一级：寄存输入信号
    reg stage2_A_B_and;                            // 第二级：A与B的与结果
    reg stage2_A_C_xor;                            // 第二级：A与C的异或结果
    reg stage3_nand_result;                        // 第三级：与非结果
    reg stage3_xnor_result;                        // 第三级：同或结果
    reg stage4_xor_intermediate;                   // 第四级：中间异或结果
    
    // 流水线第一级 - 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A_reg <= 1'b0;
            stage1_B_reg <= 1'b0;
            stage1_C_reg <= 1'b0;
        end else begin
            stage1_A_reg <= A;
            stage1_B_reg <= B;
            stage1_C_reg <= C;
        end
    end
    
    // 流水线第二级 - 计算基本逻辑操作的中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_A_B_and <= 1'b0;
            stage2_A_C_xor <= 1'b0;
        end else begin
            stage2_A_B_and <= stage1_A_reg & stage1_B_reg;  // A与B的与运算
            stage2_A_C_xor <= stage1_A_reg ^ stage1_C_reg;  // A与C的异或运算
        end
    end
    
    // 流水线第三级 - 完成基本逻辑门运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_nand_result <= 1'b1;  // 与非门默认值
            stage3_xnor_result <= 1'b0;  // 同或门默认值
        end else begin
            stage3_nand_result <= ~stage2_A_B_and;  // 完成与非运算
            stage3_xnor_result <= ~stage2_A_C_xor;  // 完成同或运算
        end
    end
    
    // 流水线第四级 - 组合第三级的结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_xor_intermediate <= 1'b0;  // 异或门默认值
        end else begin
            stage4_xor_intermediate <= stage3_nand_result ^ stage3_xnor_result;  // 异或运算
        end
    end
    
    // 流水线输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;  // 输出默认值
        end else begin
            Y <= stage4_xor_intermediate;  // 最终输出结果
        end
    end
    
endmodule