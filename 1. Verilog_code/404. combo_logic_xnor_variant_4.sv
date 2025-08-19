//SystemVerilog
module combo_logic_xnor (
    input  wire clk,     // 添加时钟信号用于流水线
    input  wire rst_n,   // 添加复位信号
    input  wire in_data1, 
    input  wire in_data2,
    output wire out_data
);

    // 内部信号定义
    wire stage1_xor_result;
    reg  stage1_xor_reg;
    reg  stage2_result_reg;
    
    // 第一级：计算XOR结果
    assign stage1_xor_result = in_data1 ^ in_data2;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_xor_reg <= 1'b0;
        end else begin
            stage1_xor_reg <= stage1_xor_result;
        end
    end
    
    // 第二级：取反操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result_reg <= 1'b0;
        end else begin
            stage2_result_reg <= ~stage1_xor_reg;
        end
    end
    
    // 输出结果
    assign out_data = stage2_result_reg;
    
endmodule