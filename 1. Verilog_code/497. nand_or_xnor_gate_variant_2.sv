//SystemVerilog
/* IEEE 1364-2005 Verilog标准 */
module nand_or_xnor_gate (
    input wire clk,        // 时钟输入
    input wire rst_n,      // 复位信号（低有效）
    input wire A, B, C,    // 数据输入
    output reg Y           // 数据输出
);
    // 阶段1：计算中间结果
    reg stage1_and_temp;     // A与B的与结果
    reg stage1_nand_result;  // A与B的与非结果
    reg stage1_xor_temp;     // A与C的异或结果
    reg stage1_xnor_result;  // A与C的同或结果
    reg stage1_A, stage1_B, stage1_C; // 寄存输入信号
    
    // 阶段2：计算最终结果
    reg stage2_result;      // 最终结果
    
    // 阶段1：寄存输入并计算中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_C <= 1'b0;
            stage1_and_temp <= 1'b0;
            stage1_nand_result <= 1'b0;
            stage1_xor_temp <= 1'b0;
            stage1_xnor_result <= 1'b0;
        end 
        else begin
            // 寄存输入信号
            stage1_A <= A;
            stage1_B <= B;
            stage1_C <= C;
            
            // 计算AND中间结果
            stage1_and_temp <= A & B;
            // 计算NAND结果
            stage1_nand_result <= ~stage1_and_temp;
            
            // 计算XOR中间结果
            stage1_xor_temp <= C ^ A;
            // 计算XNOR结果
            stage1_xnor_result <= ~stage1_xor_temp;
        end
    end
    
    // 阶段2：计算最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end 
        else begin
            // 分解OR操作为条件判断
            if (stage1_nand_result == 1'b1 || stage1_xnor_result == 1'b1) begin
                stage2_result <= 1'b1;
            end
            else begin
                stage2_result <= 1'b0;
            end
        end
    end
    
    // 最终输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end 
        else begin
            Y <= stage2_result;
        end
    end
    
endmodule