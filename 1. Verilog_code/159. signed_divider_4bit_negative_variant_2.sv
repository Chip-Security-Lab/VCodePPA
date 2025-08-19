//SystemVerilog
// Top-level module
module signed_divider_4bit_negative (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    // Internal signals
    wire signed [3:0] abs_dividend;
    wire signed [3:0] abs_divisor;
    wire sign;
    wire signed [3:0] unsigned_quotient;
    wire signed [3:0] unsigned_remainder;

    // Instantiate sign handler
    sign_handler sign_handler_inst (
        .a(a),
        .b(b),
        .abs_dividend(abs_dividend),
        .abs_divisor(abs_divisor),
        .sign(sign)
    );

    // Instantiate unsigned divider
    unsigned_divider_4bit unsigned_divider_inst (
        .dividend(abs_dividend),
        .divisor(abs_divisor),
        .quotient(unsigned_quotient),
        .remainder(unsigned_remainder)
    );

    // Instantiate output formatter
    output_formatter output_formatter_inst (
        .unsigned_quotient(unsigned_quotient),
        .unsigned_remainder(unsigned_remainder),
        .sign(sign),
        .a_sign(a[3]),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

// Sign handler module
module sign_handler (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] abs_dividend,
    output signed [3:0] abs_divisor,
    output sign
);

    assign abs_dividend = (a[3]) ? -a : a;
    assign abs_divisor = (b[3]) ? -b : b;
    assign sign = a[3] ^ b[3];

endmodule

// Unsigned divider module
module unsigned_divider_4bit (
    input signed [3:0] dividend,
    input signed [3:0] divisor,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    reg signed [3:0] q;
    reg signed [3:0] r;
    reg [2:0] count;

    always @(*) begin
        q = 0;
        r = 0;
        
        for(count = 0; count < 4; count = count + 1) begin
            r = {r[2:0], dividend[3-count]};
            if(r[3] == 0) begin
                r = r - divisor;
                q[3-count] = 1;
            end else begin
                r = r + divisor;
                q[3-count] = 0;
            end
        end
        
        if(r[3]) r = r + divisor;
    end

    assign quotient = q;
    assign remainder = r;

endmodule

// Output formatter module
module output_formatter (
    input signed [3:0] unsigned_quotient,
    input signed [3:0] unsigned_remainder,
    input sign,
    input a_sign,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    assign quotient = sign ? -unsigned_quotient : unsigned_quotient;
    assign remainder = a_sign ? -unsigned_remainder : unsigned_remainder;

endmodule