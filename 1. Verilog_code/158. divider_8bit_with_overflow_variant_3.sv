//SystemVerilog
module divider_8bit_with_overflow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);

    reg [7:0] partial_remainder;
    reg [7:0] partial_quotient;
    reg [3:0] iteration;
    reg [7:0] divisor_shifted;
    reg [7:0] next_remainder;
    reg [7:0] next_quotient;
    reg [7:0] final_quotient;
    reg [7:0] final_remainder;
    reg overflow_flag;
    
    // 先行进位加法器相关信号
    reg [7:0] carry_propagate;
    reg [7:0] carry_generate;
    reg [7:0] carry_internal;
    reg [7:0] sum_result;
    reg [7:0] inverted_divisor;
    reg [7:0] subtraction_result;

    always @(*) begin
        if (b == 0) begin
            final_quotient = 8'b00000000;
            final_remainder = 8'b00000000;
            overflow_flag = 1'b1;
        end else begin
            partial_remainder = a;
            partial_quotient = 8'b00000000;
            divisor_shifted = b;
            
            for (iteration = 0; iteration < 8; iteration = iteration + 1) begin
                next_remainder = partial_remainder;
                next_quotient = partial_quotient;
                
                // 使用先行进位加法器实现减法
                inverted_divisor = ~divisor_shifted;
                
                // 计算进位传播和生成信号
                for (int i = 0; i < 8; i = i + 1) begin
                    carry_propagate[i] = partial_remainder[i] ^ inverted_divisor[i];
                    carry_generate[i] = partial_remainder[i] & inverted_divisor[i];
                end
                
                // 计算内部进位
                carry_internal[0] = 1'b1; // 初始进位为1（减法）
                for (int i = 1; i < 8; i = i + 1) begin
                    carry_internal[i] = carry_generate[i-1] | (carry_propagate[i-1] & carry_internal[i-1]);
                end
                
                // 计算最终结果
                for (int i = 0; i < 8; i = i + 1) begin
                    sum_result[i] = partial_remainder[i] ^ inverted_divisor[i] ^ carry_internal[i];
                end
                
                subtraction_result = sum_result;
                
                if (partial_remainder >= divisor_shifted) begin
                    next_remainder = subtraction_result;
                    next_quotient = partial_quotient | (8'b00000001 << iteration);
                end
                
                partial_remainder = next_remainder;
                partial_quotient = next_quotient;
                divisor_shifted = divisor_shifted >> 1;
            end
            
            final_quotient = partial_quotient;
            final_remainder = partial_remainder;
            overflow_flag = 1'b0;
        end
    end

    assign quotient = final_quotient;
    assign remainder = final_remainder;
    assign overflow = overflow_flag;

endmodule