//SystemVerilog
module divider_4bit_with_overflow (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder,
    output overflow
);
    wire zero_divisor = ~|b;
    wire [3:0] div_result = a / b;
    wire [3:0] mod_result = a % b;
    
    // 使用多路复用器结构替代三元运算符
    wire [3:0] quotient_mux [1:0];
    wire [3:0] remainder_mux [1:0];
    
    assign quotient_mux[0] = div_result;
    assign quotient_mux[1] = 4'b0000;
    assign remainder_mux[0] = mod_result;
    assign remainder_mux[1] = 4'b0000;
    
    assign quotient = quotient_mux[zero_divisor];
    assign remainder = remainder_mux[zero_divisor];
    assign overflow = zero_divisor;
endmodule