//SystemVerilog
module signed_divider_8bit_negative (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);

    // Control signals
    wire [7:0] abs_dividend;
    wire [7:0] abs_divisor;
    wire quotient_sign;
    wire remainder_sign;

    // Absolute value calculation
    absolute_value #(.WIDTH(8)) abs_dividend_calc (
        .in(a),
        .out(abs_dividend)
    );

    absolute_value #(.WIDTH(8)) abs_divisor_calc (
        .in(b),
        .out(abs_divisor)
    );

    // Sign calculation
    sign_calculator #(.WIDTH(8)) sign_calc (
        .dividend(a),
        .divisor(b),
        .quotient_sign(quotient_sign),
        .remainder_sign(remainder_sign)
    );

    // Unsigned division
    wire [7:0] unsigned_quotient;
    wire [7:0] unsigned_remainder;

    unsigned_divider #(.WIDTH(8)) unsigned_div (
        .dividend(abs_dividend),
        .divisor(abs_divisor),
        .quotient(unsigned_quotient),
        .remainder(unsigned_remainder)
    );

    // Result sign application
    sign_applicator #(.WIDTH(8)) quotient_sign_app (
        .in(unsigned_quotient),
        .sign(quotient_sign),
        .out(quotient)
    );

    sign_applicator #(.WIDTH(8)) remainder_sign_app (
        .in(unsigned_remainder),
        .sign(remainder_sign),
        .out(remainder)
    );

endmodule

module absolute_value #(
    parameter WIDTH = 8
)(
    input signed [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);
    assign out = in[WIDTH-1] ? -in : in;
endmodule

module sign_calculator #(
    parameter WIDTH = 8
)(
    input signed [WIDTH-1:0] dividend,
    input signed [WIDTH-1:0] divisor,
    output quotient_sign,
    output remainder_sign
);
    assign quotient_sign = dividend[WIDTH-1] ^ divisor[WIDTH-1];
    assign remainder_sign = dividend[WIDTH-1];
endmodule

module unsigned_divider #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] dividend,
    input [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);
    reg [WIDTH-1:0] q;
    reg [WIDTH-1:0] r;
    reg [WIDTH-1:0] d;
    reg [WIDTH-1:0] n;
    integer i;

    always @(*) begin
        q = 0;
        r = 0;
        d = divisor;
        n = dividend;
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            r = {r[WIDTH-2:0], n[WIDTH-1]};
            n = {n[WIDTH-2:0], 1'b0};
            
            if (r >= d) begin
                r = r - d;
                q = {q[WIDTH-2:0], 1'b1};
            end else begin
                q = {q[WIDTH-2:0], 1'b0};
            end
        end
    end

    assign quotient = q;
    assign remainder = r;
endmodule

module sign_applicator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] in,
    input sign,
    output signed [WIDTH-1:0] out
);
    assign out = sign ? -in : in;
endmodule