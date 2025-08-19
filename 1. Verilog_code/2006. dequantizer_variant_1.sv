//SystemVerilog
// -----------------------------------------------------------------------------
// Top-Level Dequantizer Module (Hierarchical)
// -----------------------------------------------------------------------------
module dequantizer #(
    parameter B = 8
)(
    input  wire signed [15:0] qval,
    input  wire signed [15:0] scale,
    output wire signed [15:0] deq
);

    // Internal signal grouping
    wire signed [31:0] mult_result;
    wire signed [15:0] clamped_result;

    // Multiplication Unit: Computes qval * scale
    dequantizer_mult_unit u_mult_unit (
        .qval      (qval),
        .scale     (scale),
        .product   (mult_result)
    );

    // Clamping Unit: Clamps result to valid 16-bit signed range
    dequantizer_clamp_unit u_clamp_unit (
        .value_in  (mult_result[15:0]),
        .value_out (clamped_result)
    );

    assign deq = clamped_result;

endmodule

// -----------------------------------------------------------------------------
// dequantizer_mult_unit
// Performs signed multiplication of quantized value and scale factor
// -----------------------------------------------------------------------------
module dequantizer_mult_unit (
    input  wire signed [15:0] qval,
    input  wire signed [15:0] scale,
    output wire signed [31:0] product
);
    assign product = qval * scale;
endmodule

// -----------------------------------------------------------------------------
// dequantizer_clamp_unit
// Clamps the input value to the range [-32768, 32767] for 16-bit signed output
// -----------------------------------------------------------------------------
module dequantizer_clamp_unit (
    input  wire signed [15:0] value_in,
    output reg  signed [15:0] value_out
);
    always @* begin
        if (value_in > 16'sd32767)
            value_out = 16'sd32767;
        else if (value_in < -16'sd32768)
            value_out = -16'sd32768;
        else
            value_out = value_in;
    end
endmodule