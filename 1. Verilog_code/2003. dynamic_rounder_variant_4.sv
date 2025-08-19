//SystemVerilog
// Top-level module: Hierarchical and modularized dynamic rounder

module dynamic_rounder #(
    parameter W = 16
)(
    input  [W+2:0] in,
    input          mode,
    output [W-1:0] out
);

    // Internal signals for submodule connections
    wire [W-1:0] addend_wire;
    wire         round_bit_wire;
    wire [2:0]   adder_sum_wire;
    wire         adder_cout_wire;
    wire [W-1:0] rounded_wire;

    // Extract addend part (bits [W+2:3])
    assign addend_wire = in[W+2:3];

    // Calculate the rounding bit (OR reduction of in[2:0])
    round_bit_generator u_round_bit_generator (
        .in_bits    (in[2:0]),
        .round_bit  (round_bit_wire)
    );

    // 3-bit Kogge-Stone adder for LSB rounding
    kogge_stone_adder_3bit u_kogge_stone_adder_3bit (
        .a      (addend_wire[2:0]),
        .b      ({2'b00, round_bit_wire}),
        .sum    (adder_sum_wire),
        .cout   (adder_cout_wire)
    );

    // Combine the rounded LSBs with the untouched MSBs
    rounded_result_combiner #(.W(W)) u_rounded_result_combiner (
        .orig_addend (addend_wire),
        .lsb_sum     (adder_sum_wire),
        .final_sum   (rounded_wire)
    );

    // Output selection based on mode
    output_selector #(.W(W)) u_output_selector (
        .mode          (mode),
        .rounded_value (rounded_wire),
        .plain_value   (addend_wire),
        .out           (out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: round_bit_generator
// Purpose: Performs OR reduction to produce the rounding bit from 3 LSBs
//------------------------------------------------------------------------------
module round_bit_generator (
    input  [2:0] in_bits,
    output       round_bit
);
    assign round_bit = |in_bits;
endmodule

//------------------------------------------------------------------------------
// Submodule: kogge_stone_adder_3bit
// Purpose: 3-bit Kogge-Stone parallel prefix adder for LSB rounding
//------------------------------------------------------------------------------
module kogge_stone_adder_3bit (
    input  [2:0] a,
    input  [2:0] b,
    output [2:0] sum,
    output       cout
);
    wire [2:0] g, p;
    wire [2:0] c;

    // Generate and propagate signals
    assign g = a & b;
    assign p = a ^ b;

    // Carry chain
    assign c[0] = 1'b0;
    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);

    // Sums
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];

    // Final carry-out
    assign cout = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
endmodule

//------------------------------------------------------------------------------
// Submodule: rounded_result_combiner
// Purpose: Combines the adder result with untouched MSBs to form the final sum
//------------------------------------------------------------------------------
module rounded_result_combiner #(
    parameter W = 16
)(
    input  [W-1:0] orig_addend,
    input  [2:0]   lsb_sum,
    output [W-1:0] final_sum
);
    assign final_sum[2:0]   = lsb_sum;
    assign final_sum[W-1:3] = orig_addend[W-1:3];
endmodule

//------------------------------------------------------------------------------
// Submodule: output_selector
// Purpose: Selects between rounded or plain addend based on mode
//------------------------------------------------------------------------------
module output_selector #(
    parameter W = 16
)(
    input              mode,
    input  [W-1:0]     rounded_value,
    input  [W-1:0]     plain_value,
    output reg [W-1:0] out
);
    always @(*) begin
        if (mode)
            out = rounded_value;
        else
            out = plain_value;
    end
endmodule