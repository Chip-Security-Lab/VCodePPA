//SystemVerilog
module dynamic_rounder #(
    parameter W = 16
)(
    input  [W+2:0] in,
    input          mode,
    output [W-1:0] out
);

    // Stage 1: Extract high bits and check remainder
    reg  [W-1:0] stage1_in_high;
    reg          stage1_remainder_nonzero;
    always @(*) begin
        stage1_in_high = in[W+2:3];
        stage1_remainder_nonzero = |in[2:0];
    end

    // Stage 2: Compute incremented value and xor mask
    reg [W-1:0] stage2_incremented;
    reg [W-1:0] stage2_xor_mask;
    always @(*) begin
        stage2_incremented = stage1_in_high + 1'b1;
        stage2_xor_mask = stage2_incremented ^ stage1_in_high;
    end

    // Stage 3: Generate rounding mask
    reg [W-1:0] stage3_rounding_mask;
    always @(*) begin
        stage3_rounding_mask = {W{mode & stage1_remainder_nonzero}} & stage2_xor_mask;
    end

    // Stage 4: Final output
    assign out = stage1_in_high | stage3_rounding_mask;

endmodule