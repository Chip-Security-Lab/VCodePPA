//SystemVerilog
module signed_divider_16bit (
    input signed [15:0] a,
    input signed [15:0] b,
    output signed [15:0] quotient,
    output signed [15:0] remainder
);

    wire a_sign, b_sign;
    wire [14:0] a_abs, b_abs;
    
    sign_handler sign_handler_inst (
        .a(a),
        .b(b),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_abs(a_abs),
        .b_abs(b_abs)
    );

    wire [14:0] quotient_abs, remainder_abs;
    
    divider_core divider_core_inst (
        .a_abs(a_abs),
        .b_abs(b_abs),
        .quotient_abs(quotient_abs),
        .remainder_abs(remainder_abs)
    );

    result_handler result_handler_inst (
        .quotient_abs(quotient_abs),
        .remainder_abs(remainder_abs),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module sign_handler (
    input signed [15:0] a,
    input signed [15:0] b,
    output reg a_sign,
    output reg b_sign,
    output reg [14:0] a_abs,
    output reg [14:0] b_abs
);
    wire [14:0] a_neg, b_neg;
    
    assign a_sign = a[15];
    assign b_sign = b[15];
    assign a_neg = -a[14:0];
    assign b_neg = -b[14:0];
    
    always @(*) begin
        a_abs = a_sign ? a_neg : a[14:0];
        b_abs = b_sign ? b_neg : b[14:0];
    end
endmodule

module divider_core (
    input [14:0] a_abs,
    input [14:0] b_abs,
    output reg [14:0] quotient_abs,
    output reg [14:0] remainder_abs
);
    reg [14:0] dividend;
    reg [14:0] divisor;
    reg [14:0] quotient;
    reg [14:0] remainder;
    reg [14:0] remainder_next;
    reg borrow;
    integer i;

    always @(*) begin
        dividend = a_abs;
        divisor = b_abs;
        quotient = 0;
        remainder = 0;
        remainder_next = 0;
        borrow = 0;

        for (i = 14; i >= 0; i = i - 1) begin
            remainder = {remainder[13:0], dividend[i]};
            
            // 使用显式多路复用器结构
            remainder_next = remainder - divisor;
            borrow = (remainder < divisor) ? 1'b1 : 1'b0;
            
            // 使用显式多路复用器选择结果
            remainder = borrow ? remainder : remainder_next;
            quotient[i] = ~borrow;
        end
        
        quotient_abs = quotient;
        remainder_abs = remainder;
    end
endmodule

module result_handler (
    input [14:0] quotient_abs,
    input [14:0] remainder_abs,
    input a_sign,
    input b_sign,
    output reg signed [15:0] quotient,
    output reg signed [15:0] remainder
);
    wire signed [15:0] quotient_pos, quotient_neg;
    wire signed [15:0] remainder_pos, remainder_neg;
    wire sign_xor;
    
    assign quotient_pos = {1'b0, quotient_abs};
    assign quotient_neg = -{1'b0, quotient_abs};
    assign remainder_pos = {1'b0, remainder_abs};
    assign remainder_neg = -{1'b0, remainder_abs};
    assign sign_xor = a_sign ^ b_sign;
    
    always @(*) begin
        quotient = sign_xor ? quotient_neg : quotient_pos;
        remainder = a_sign ? remainder_neg : remainder_pos;
    end
endmodule