module signed_divider_8bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);

    // 符号处理模块
    wire sign_a = a[7];
    wire sign_b = b[7];
    wire [6:0] abs_a;
    wire [6:0] abs_b;
    
    // 使用显式多路复用器替代三元运算符
    assign abs_a = (sign_a == 1'b1) ? (~a[6:0] + 1'b1) : a[6:0];
    assign abs_b = (sign_b == 1'b1) ? (~b[6:0] + 1'b1) : b[6:0];
    
    // 无符号除法模块
    wire [6:0] abs_quotient;
    wire [6:0] abs_remainder;
    
    unsigned_divider_7bit u_div (
        .a(abs_a),
        .b(abs_b),
        .quotient(abs_quotient),
        .remainder(abs_remainder)
    );
    
    // 结果符号处理 - 使用显式多路复用器
    wire [7:0] pos_quotient = {1'b0, abs_quotient};
    wire [7:0] neg_quotient = ~{1'b0, abs_quotient} + 1'b1;
    wire [7:0] pos_remainder = {1'b0, abs_remainder};
    wire [7:0] neg_remainder = ~{1'b0, abs_remainder} + 1'b1;
    
    assign quotient = (sign_a ^ sign_b) ? neg_quotient : pos_quotient;
    assign remainder = sign_a ? neg_remainder : pos_remainder;

endmodule

module unsigned_divider_7bit (
    input [6:0] a,
    input [6:0] b,
    output reg [6:0] quotient,
    output reg [6:0] remainder
);
    
    reg [6:0] dividend;
    reg [6:0] divisor;
    reg [6:0] temp_quotient;
    reg [6:0] temp_remainder;
    
    always @(*) begin
        dividend = a;
        divisor = b;
        temp_quotient = 7'b0;
        temp_remainder = 7'b0;
        
        if (divisor != 0) begin
            for (integer i = 6; i >= 0; i = i - 1) begin
                temp_remainder = {temp_remainder[5:0], dividend[i]};
                if (temp_remainder >= divisor) begin
                    temp_remainder = temp_remainder - divisor;
                    temp_quotient[i] = 1'b1;
                end
            end
        end
        
        quotient = temp_quotient;
        remainder = temp_remainder;
    end
    
endmodule