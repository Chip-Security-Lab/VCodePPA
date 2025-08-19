//SystemVerilog
module or_gate_4input_delayed (
    input  wire clk,     // 添加时钟输入用于流水线
    input  wire rst_n,   // 添加复位信号
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire d,
    output wire y
);
    // 第一级流水线 - 处理输入对
    reg a_reg, b_reg, c_reg, d_reg;
    reg ab_stage1, cd_stage1;
    
    // 第二级流水线 - 合并结果
    reg y_stage2;
    
    // 合并所有具有相同触发条件的always块
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化所有寄存器
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            c_reg <= 1'b0;
            d_reg <= 1'b0;
            ab_stage1 <= 1'b0;
            cd_stage1 <= 1'b0;
            y_stage2 <= 1'b0;
        end else begin
            // 第一级：输入寄存化
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            
            // 第二级：并行计算两组或操作
            ab_stage1 <= a_reg | b_reg;
            cd_stage1 <= c_reg | d_reg;
            
            // 第三级：合并两组结果
            y_stage2 <= ab_stage1 | cd_stage1;
        end
    end
    
    // 输出赋值
    assign y = y_stage2;
    
endmodule