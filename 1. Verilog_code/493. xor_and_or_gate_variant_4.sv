//SystemVerilog
//IEEE 1364-2005 Verilog标准
module xor_and_or_gate (
    input wire clk,       // 时钟输入
    input wire rst_n,     // 复位信号
    input wire A, B, C,   // 数据输入A, B, C
    output reg Y          // 流水线输出Y
);
    // 定义数据流阶段信号
    reg stage1_A, stage1_B, stage1_C;     // 第一级寄存器
    reg stage2_xor_result, stage2_or_result; // 第二级寄存器
    
    // 内部组合逻辑结果
    wire xor_result, or_result;
    
    // 第一级：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
            stage1_C <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
            stage1_C <= C;
        end
    end
    
    // 第一级组合逻辑计算
    assign xor_result = stage1_A ^ stage1_B;
    assign or_result = stage1_A | stage1_C;
    
    // 第二级：寄存中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_result <= 1'b0;
            stage2_or_result <= 1'b0;
        end else begin
            stage2_xor_result <= xor_result;
            stage2_or_result <= or_result;
        end
    end
    
    // 第三级：最终结果计算与寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_xor_result & stage2_or_result;
        end
    end
endmodule