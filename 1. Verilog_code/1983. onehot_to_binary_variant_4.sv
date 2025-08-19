//SystemVerilog
//-----------------------------------------------------------------------------
// Top-level Module: onehot_to_binary
// Description: Converts a one-hot input vector to binary encoding.
//-----------------------------------------------------------------------------
module onehot_to_binary #(
    parameter ONE_HOT_WIDTH = 8
)(
    input  wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output wire [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);

    wire [$clog2(ONE_HOT_WIDTH)-1:0] binary_encoded;

    onehot_encoder #(
        .ONE_HOT_WIDTH(ONE_HOT_WIDTH)
    ) u_onehot_encoder (
        .onehot_vector(onehot_in),
        .binary_code(binary_encoded)
    );

    assign binary_out = binary_encoded;

endmodule

//-----------------------------------------------------------------------------
// Submodule: onehot_encoder
// Description: Encodes a one-hot input vector to its binary index.
// Optimized for efficient comparison logic
//-----------------------------------------------------------------------------
module onehot_encoder #(
    parameter ONE_HOT_WIDTH = 8
)(
    input  wire [ONE_HOT_WIDTH-1:0] onehot_vector,
    output wire [$clog2(ONE_HOT_WIDTH)-1:0] binary_code
);
    // Priority encoder logic using bitwise OR and generate
    genvar idx, bit_idx;
    wire [$clog2(ONE_HOT_WIDTH)-1:0] bitwise_or [ONE_HOT_WIDTH-1:0];

    generate
        for (bit_idx = 0; bit_idx < $clog2(ONE_HOT_WIDTH); bit_idx = bit_idx + 1) begin : gen_bit
            assign binary_code[bit_idx] = |(
                onehot_vector & ({{ONE_HOT_WIDTH{1'b1}}} << bit_idx)
            );
        end
    endgenerate
endmodule