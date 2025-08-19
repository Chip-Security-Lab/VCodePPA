//SystemVerilog
module divider_8bit_with_overflow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);

    wire [7:0] temp_quotient;
    wire [7:0] temp_remainder;
    wire div_by_zero;

    divider_core u_divider_core (
        .a(a),
        .b(b),
        .quotient(temp_quotient),
        .remainder(temp_remainder)
    );

    overflow_detector u_overflow_detector (
        .b(b),
        .overflow(div_by_zero)
    );

    output_controller u_output_controller (
        .temp_quotient(temp_quotient),
        .temp_remainder(temp_remainder),
        .div_by_zero(div_by_zero),
        .quotient(quotient),
        .remainder(remainder),
        .overflow(overflow)
    );

endmodule

module divider_core (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder
);
    assign quotient = a / b;
    assign remainder = a % b;
endmodule

module overflow_detector (
    input [7:0] b,
    output overflow
);
    assign overflow = ~(|b);
endmodule

module output_controller (
    input [7:0] temp_quotient,
    input [7:0] temp_remainder,
    input div_by_zero,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);
    reg [7:0] quotient_reg;
    reg [7:0] remainder_reg;
    reg overflow_reg;

    always @(*) begin
        if (div_by_zero) begin
            quotient_reg = 8'b00000000;
            remainder_reg = 8'b00000000;
            overflow_reg = 1'b1;
        end else begin
            quotient_reg = temp_quotient;
            remainder_reg = temp_remainder;
            overflow_reg = 1'b0;
        end
    end

    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    assign overflow = overflow_reg;
endmodule