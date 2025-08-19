//SystemVerilog
// multiplier_8bit_signed_top.v
module multiplier_8bit_signed (
    input  wire signed [7:0] multiplicand,
    input  wire signed [7:0] multiplier,
    output wire signed [15:0] product
);

    // Internal signals
    wire signed [15:0] multiplicand_ext;
    wire signed [15:0] multiplier_ext;
    wire signed [15:0] partial_sum;

    // Sign-extension of multiplicand
    sign_extender #(
        .IN_WIDTH(8),
        .OUT_WIDTH(16)
    ) u_signext_multiplicand (
        .in_data(multiplicand),
        .out_data(multiplicand_ext)
    );

    // Sign-extension of multiplier
    sign_extender #(
        .IN_WIDTH(8),
        .OUT_WIDTH(16)
    ) u_signext_multiplier (
        .in_data(multiplier),
        .out_data(multiplier_ext)
    );

    // Partial products accumulation
    booth_partial_sum #(
        .WIDTH(16),
        .MULT_WIDTH(8)
    ) u_partial_sum (
        .multiplicand_ext(multiplicand_ext),
        .multiplier_ext(multiplier_ext),
        .partial_sum(partial_sum)
    );

    assign product = partial_sum;

endmodule

// sign_extender.v
// ---------------------------------------------------------------------------
// Function: Sign extension module
// Extends the input signed data from IN_WIDTH to OUT_WIDTH
// ---------------------------------------------------------------------------
module sign_extender #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 16
)(
    input  wire signed [IN_WIDTH-1:0] in_data,
    output wire signed [OUT_WIDTH-1:0] out_data
);
    assign out_data = {{(OUT_WIDTH-IN_WIDTH){in_data[IN_WIDTH-1]}}, in_data};
endmodule

// booth_partial_sum.v
// ---------------------------------------------------------------------------
// Function: Partial product sum for signed multiplication using shift-add
// Calculates the sum of shifted multiplicand bits based on multiplier bits
// ---------------------------------------------------------------------------
module booth_partial_sum #(
    parameter WIDTH = 16,
    parameter MULT_WIDTH = 8
)(
    input  wire signed [WIDTH-1:0] multiplicand_ext,
    input  wire signed [WIDTH-1:0] multiplier_ext,
    output reg  signed [WIDTH-1:0] partial_sum
);
    integer bit_index;
    always @(*) begin
        partial_sum = {WIDTH{1'b0}};
        for (bit_index = 0; bit_index < MULT_WIDTH; bit_index = bit_index + 1) begin
            if (multiplier_ext[bit_index])
                partial_sum = partial_sum + (multiplicand_ext <<< bit_index);
        end
    end
endmodule