//SystemVerilog
// Top-level module: Hierarchical binary-to-onehot converter

module binary_to_onehot 
#(
    parameter BINARY_WIDTH=3
)
(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire [2**BINARY_WIDTH-1:0] onehot_out
);

    // Internal signals
    wire [BINARY_WIDTH-1:0] sum_result;
    wire [BINARY_WIDTH-1:0] carry_vector;

    // Instantiate Subtractor module
    binary_subtractor #(
        .WIDTH(BINARY_WIDTH)
    ) u_binary_subtractor (
        .in_a    ({BINARY_WIDTH{1'b1}}),   // three_bit_one
        .in_b    (binary_in),
        .sum     (sum_result),
        .carry   (carry_vector)
    );

    // Instantiate One-hot Encoder module
    onehot_encoder #(
        .WIDTH(BINARY_WIDTH)
    ) u_onehot_encoder (
        .bin_in      (binary_in),
        .onehot_out  (onehot_out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: binary_subtractor
// Function: Parameterized subtractor, computes sum = in_a - in_b
//------------------------------------------------------------------------------
module binary_subtractor #(
    parameter WIDTH = 3
)(
    input  wire [WIDTH-1:0] in_a,
    input  wire [WIDTH-1:0] in_b,
    output wire [WIDTH-1:0] sum,
    output wire [WIDTH-1:0] carry
);
    // Subtraction logic: sum = in_a - in_b, implemented with conditional sum subtraction
    wire [WIDTH-1:0] not_in_b;
    assign not_in_b = ~in_b;

    // Carry and sum logic for each bit
    assign carry[0] = not_in_b[0];
    assign sum[0]   = in_a[0] ^ in_b[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_subtractor
            assign carry[i] = (~in_b[i] & carry[i-1]) | (~in_b[i] & ~in_b[i-1]) | (carry[i-1] & ~in_b[i-1]);
            assign sum[i]   = in_a[i] ^ in_b[i] ^ carry[i-1];
        end
    endgenerate
endmodule

//------------------------------------------------------------------------------
// Submodule: onehot_encoder
// Function: Parameterized binary-to-onehot encoder
//------------------------------------------------------------------------------
module onehot_encoder #(
    parameter WIDTH = 3
)(
    input  wire [WIDTH-1:0] bin_in,
    output reg  [2**WIDTH-1:0] onehot_out
);
    integer idx;
    always @* begin
        onehot_out = { (2**WIDTH){1'b0} };
        for (idx = 0; idx < 2**WIDTH; idx = idx + 1) begin
            if (idx == bin_in)
                onehot_out[idx] = 1'b1;
            else
                onehot_out[idx] = 1'b0;
        end
    end
endmodule