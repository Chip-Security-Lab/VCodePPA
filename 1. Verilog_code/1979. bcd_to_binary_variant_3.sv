//SystemVerilog
// Top-level module: Hierarchical BCD to Binary Converter

module bcd_to_binary #(
    parameter DIGITS = 3
)(
    input  wire [4*DIGITS-1:0] bcd_in,
    output wire [DIGITS*3+3:0] binary_out
);

    // Internal signals for submodule connections
    wire [DIGITS*3+3:0] accumulator_wire;

    // Instantiate the BCD Accumulation and Conversion Module
    bcd_accumulator #(
        .DIGITS(DIGITS)
    ) u_bcd_accumulator (
        .bcd_in         (bcd_in),
        .accumulated_out(accumulator_wire)
    );

    // Assign output
    assign binary_out = accumulator_wire;

endmodule

// -------------------------------------------------------------
// Submodule: bcd_accumulator
// Purpose: Iteratively multiplies accumulated value by 10 and adds next BCD digit
// -------------------------------------------------------------
module bcd_accumulator #(
    parameter DIGITS = 3
)(
    input  wire [4*DIGITS-1:0] bcd_in,
    output reg  [DIGITS*3+3:0] accumulated_out
);

    integer i;
    reg [DIGITS*3+3:0] temp;
    reg [3:0] bcd_digit;

    // Optimized multiply-by-10 using shift-and-add (10x = (x<<3) + (x<<1))
    function [DIGITS*3+3:0] mul10;
        input [DIGITS*3+3:0] val;
        begin
            mul10 = (val << 3) + (val << 1);
        end
    endfunction

    always @* begin
        temp = 0;
        for (i = 0; i < DIGITS; i = i + 1) begin
            bcd_digit = bcd_in[4*i+3 -: 4];
            temp = mul10(temp) + bcd_digit;
        end
        accumulated_out = temp;
    end

endmodule

// -------------------------------------------------------------
// Submodule: signed_mult8
// Purpose: Performs signed multiplication for two 8-bit operands using shift-and-add
// -------------------------------------------------------------
module signed_mult8 (
    input  wire signed [7:0] a,
    input  wire signed [7:0] b,
    output reg  signed [15:0] product
);
    integer k;
    reg [15:0] unsigned_result;
    reg [7:0] abs_a, abs_b;
    reg sign_a, sign_b, sign_product;

    always @* begin
        sign_a = a[7];
        sign_b = b[7];
        abs_a = sign_a ? (~a + 1'b1) : a;
        abs_b = sign_b ? (~b + 1'b1) : b;
        unsigned_result = 0;
        for (k = 0; k < 8; k = k + 1) begin
            // Simplified: if (abs_b[k]) unsigned_result = unsigned_result + (abs_a << k);
            unsigned_result = unsigned_result | ({8'd0, abs_b[k]} & (abs_a << k));
        end
        sign_product = sign_a ^ sign_b;
        product = sign_product ? (~unsigned_result + 1'b1) : unsigned_result;
    end
endmodule