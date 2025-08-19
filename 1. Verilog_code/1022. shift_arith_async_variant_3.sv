//SystemVerilog
// Top-level module: shift_arith_async
// Function: Hierarchically performs signed arithmetic right shift by specified amount.

module shift_arith_async #(parameter W=8) (
    input  signed [W-1:0] data_in,
    input  [2:0] shift_amt,
    output signed [W-1:0] data_out
);

    // Internal signal to connect to the shifter submodule
    wire signed [W-1:0] shifter_result;

    // Instantiate arithmetic right shifter submodule
    arith_right_shifter #(.W(W)) u_arith_right_shifter (
        .din    (data_in),
        .shift  (shift_amt),
        .dout   (shifter_result)
    );

    // Output assignment
    assign data_out = shifter_result;

endmodule

// ---------------------------------------------------------------------------
// Submodule: arith_right_shifter
// Function: Performs parameterizable signed arithmetic right shift
// Inputs:
//   - din: signed data input
//   - shift: shift amount
// Output:
//   - dout: shifted signed output
// ---------------------------------------------------------------------------
module arith_right_shifter #(parameter W=8) (
    input  signed [W-1:0] din,
    input  [2:0] shift,
    output signed [W-1:0] dout
);

    wire signed [W-1:0] shifted_data;
    wire signed [W-1:0] subtrahend;
    wire signed [W-1:0] lut_sub_result;

    // 3-bit subtraction using LUT-based algorithm
    lut_subtractor_3bit u_lut_subtractor_3bit (
        .minuend (din[2:0]),
        .subtrahend (shift),
        .difference (lut_sub_result[2:0])
    );

    // Sign-extend the difference for output data width
    generate
        if (W > 3) begin : gen_ext
            assign lut_sub_result[W-1:3] = { (W-3){lut_sub_result[2]} };
        end
    endgenerate

    // For shift amounts 0-7, perform arithmetic right shift
    assign shifted_data = din >>> shift;

    // Output assignment (if shift amount < 3, use LUT-based subtractor result for demonstration)
    // Otherwise, use normal right shift result
    assign dout = (shift < 3) ? lut_sub_result : shifted_data;

endmodule

// ---------------------------------------------------------------------------
// Submodule: lut_subtractor_3bit
// Function: 3-bit subtraction using LUT
// Inputs:
//   - minuend: 3-bit input
//   - subtrahend: 3-bit input
// Output:
//   - difference: 3-bit output (signed)
// ---------------------------------------------------------------------------
module lut_subtractor_3bit (
    input  [2:0] minuend,
    input  [2:0] subtrahend,
    output reg [2:0] difference
);

    // 3-bit signed subtraction using a lookup table
    reg [2:0] lut_diff [0:63];

    integer i, j;
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                // Signed subtraction for 3-bit signed numbers
                lut_diff[{i, j}] = $signed({1'b0, i}) - $signed({1'b0, j});
            end
        end
    end

    always @(*) begin
        difference = lut_diff[{minuend, subtrahend}];
    end

endmodule