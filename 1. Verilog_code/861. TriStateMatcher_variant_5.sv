//SystemVerilog
module TriStateMatcher #(
    parameter WIDTH = 8
)(
    input wire clk,                  // 时钟信号用于流水线寄存器
    input wire rst_n,                // 复位信号
    input wire [WIDTH-1:0] data,     // 输入数据
    input wire [WIDTH-1:0] pattern,  // 匹配模式
    input wire [WIDTH-1:0] mask,     // 掩码（0=无关位）
    output reg match                 // 匹配结果输出
);

    // 第一级流水线: 应用掩码
    reg [WIDTH-1:0] masked_data_r;
    reg [WIDTH-1:0] masked_pattern_r;
    
    // 第二级流水线：使用条件反相减法器算法
    reg [WIDTH:0] sub_result_r;      // 减法结果（多一位用于进位）
    reg [WIDTH-1:0] operand_a;       // 第一个操作数
    reg [WIDTH-1:0] operand_b;       // 第二个操作数
    reg direction;                   // 减法方向标志
    reg sub_zero_r;                  // 减法结果为零的标志
    
    // 第三级流水线: 比较结果
    reg compare_result_r;
    
    // 合并的流水线逻辑: 包含所有阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_r <= {WIDTH{1'b0}};
            masked_pattern_r <= {WIDTH{1'b0}};
            operand_a <= {WIDTH{1'b0}};
            operand_b <= {WIDTH{1'b0}};
            direction <= 1'b0;
            sub_result_r <= {(WIDTH+1){1'b0}};
            sub_zero_r <= 1'b0;
            compare_result_r <= 1'b0;
            match <= 1'b0;
        end else begin
            // 第一级流水线: 应用掩码
            masked_data_r <= data & mask;
            masked_pattern_r <= pattern & mask;
            
            // 第二级流水线: 准备条件反相减法器的操作数
            // 确定减法方向，始终用大数减小数，避免借位
            if (masked_data_r >= masked_pattern_r) begin
                operand_a <= masked_data_r;
                operand_b <= masked_pattern_r;
                direction <= 1'b0; // data >= pattern
            end else begin
                operand_a <= masked_pattern_r;
                operand_b <= masked_data_r;
                direction <= 1'b1; // data < pattern
            end
            
            // 执行减法运算
            sub_result_r <= {1'b0, operand_a} - {1'b0, operand_b};
            
            // 检查减法结果是否为零
            sub_zero_r <= (sub_result_r[WIDTH-1:0] == {WIDTH{1'b0}});
            
            // 第三级: 基于减法结果确定比较结果
            // 只有在减法结果为零时才匹配，无论减法方向如何
            compare_result_r <= sub_zero_r;
            
            // 第四级: 输出寄存器
            match <= compare_result_r;
        end
    end

endmodule