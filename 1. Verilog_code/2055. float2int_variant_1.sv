//SystemVerilog
module float2int #(parameter INT_BITS = 32) (
    input wire clk,
    input wire rst_n,
    input wire [31:0] float_in,  // IEEE-754 Single precision
    output reg signed [INT_BITS-1:0] int_out,
    output reg overflow
);
    // IEEE-754 fields extraction
    wire sign_bit;
    wire [7:0] exponent_field;
    wire [22:0] mantissa_field;
    wire [23:0] mantissa_with_leading;
    wire [7:0] exponent_unbiased;
    wire [INT_BITS-1:0] value_shifted;
    wire exponent_underflow, exponent_overflow, exponent_inrange;

    assign sign_bit = float_in[31];
    assign exponent_field = float_in[30:23];
    assign mantissa_field = float_in[22:0];
    assign mantissa_with_leading = {1'b1, mantissa_field}; // implicit leading 1

    // Subtract 127 using borrow subtractor
    wire [7:0] exp_borrow_result;
    wire exp_borrow_out;
    borrow_subtractor_8bit u_borrow_sub_exp127 (
        .minuend(exponent_field),
        .subtrahend(8'd127),
        .diff(exp_borrow_result),
        .borrow_out(exp_borrow_out)
    );
    assign exponent_unbiased = exp_borrow_result;

    // Range checking
    assign exponent_underflow = exp_borrow_out; // exponent < 127
    // Use borrow subtractor for overflow: exponent > (127+INT_BITS-1)
    wire [7:0] threshold_exp;
    assign threshold_exp = 8'd127 + INT_BITS - 1;
    wire [7:0] exp_overflow_borrow_result;
    wire exp_overflow_borrow_out;
    borrow_subtractor_8bit u_borrow_sub_overflow (
        .minuend(exponent_field),
        .subtrahend(threshold_exp),
        .diff(exp_overflow_borrow_result),
        .borrow_out(exp_overflow_borrow_out)
    );
    assign exponent_overflow = ~exp_overflow_borrow_out; // exponent > threshold
    assign exponent_inrange = ~exponent_underflow & ~exponent_overflow;

    // Shifted value calculation (handle left and right shifts efficiently)
    wire [47:0] mantissa_shifted;
    assign mantissa_shifted = (exponent_unbiased[7] == 1'b0) ?
                              ({24'b0, mantissa_with_leading} << exponent_unbiased) : // left shift
                              (mantissa_with_leading >> (-$signed({1'b0, exponent_unbiased}))); // right shift

    assign value_shifted = mantissa_shifted[INT_BITS-1:0];

    // 48-bit borrow subtractor for signed negation
    wire [INT_BITS-1:0] negated_value;
    wire neg_borrow_out;
    borrow_subtractor_48bit u_borrow_sub_negate (
        .minuend({INT_BITS{1'b0}}),
        .subtrahend(value_shifted),
        .diff(negated_value),
        .borrow_out(neg_borrow_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {INT_BITS{1'b0}};
            overflow <= 1'b0;
        end else begin
            if (exponent_overflow) begin
                overflow <= 1'b1;
                int_out <= sign_bit ? {1'b1, {(INT_BITS-1){1'b0}}} : {1'b0, {(INT_BITS-1){1'b1}}};
            end else if (exponent_underflow) begin
                overflow <= 1'b0;
                int_out <= {INT_BITS{1'b0}};
            end else begin
                overflow <= 1'b0;
                int_out <= sign_bit ? negated_value : value_shifted;
            end
        end
    end
endmodule

// 8-bit borrow subtractor
module borrow_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] diff,
    output wire borrow_out
);
    wire [7:0] borrow;
    genvar i;

    assign borrow[0] = (minuend[0] < subtrahend[0]);
    assign diff[0] = minuend[0] ^ subtrahend[0];

    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_borrow
            assign borrow[i] = (minuend[i] < (subtrahend[i] + borrow[i-1]));
            assign diff[i] = minuend[i] ^ subtrahend[i] ^ borrow[i-1];
        end
    endgenerate

    assign borrow_out = borrow[7];
endmodule

// 48-bit borrow subtractor
module borrow_subtractor_48bit (
    input  wire [47:0] minuend,
    input  wire [47:0] subtrahend,
    output wire [47:0] diff,
    output wire borrow_out
);
    wire [47:0] borrow;
    genvar i;

    assign borrow[0] = (minuend[0] < subtrahend[0]);
    assign diff[0] = minuend[0] ^ subtrahend[0];

    generate
        for (i = 1; i < 48; i = i + 1) begin : gen_borrow
            assign borrow[i] = (minuend[i] < (subtrahend[i] + borrow[i-1]));
            assign diff[i] = minuend[i] ^ subtrahend[i] ^ borrow[i-1];
        end
    endgenerate

    assign borrow_out = borrow[47];
endmodule