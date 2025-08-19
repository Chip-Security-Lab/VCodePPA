//SystemVerilog
// SystemVerilog

// Top module: IVMU_BinaryTree
// This module serves as the top level for the system.
// It defines the primary interface and instantiates the necessary submodules
// to process the input 'req' and generate the 'grant' based on a specific
// priority encoding scheme applied to the upper bits of 'req'.
module IVMU_BinaryTree #(parameter W=8) (
    input [W-1:0] req,  // 8-bit request input
    output [2:0] grant  // 3-bit priority encoded grant output
);

    // Define the width of the input slice that will be processed by the encoder.
    // In this case, the upper 4 bits (req[7:4]) are used.
    localparam ENCODER_INPUT_WIDTH = 4;
    // Define the width of the output grant from the encoder.
    // The grant value needs 3 bits (0-7).
    localparam ENCODER_OUTPUT_WIDTH = 3;

    // Instantiate the priority encoder submodule.
    // This submodule is responsible for implementing the specific priority logic
    // on its 4-bit input and producing the 3-bit grant output.
    // The top module connects the relevant slice of the global input 'req'
    // to this submodule's input and connects the submodule's output to the
    // top-level 'grant' output.
    priority_encoder_4bit_top3 #(
        .W_IN(ENCODER_INPUT_WIDTH),  // Configure submodule input width
        .W_OUT(ENCODER_OUTPUT_WIDTH) // Configure submodule output width
    ) u_priority_encoder (
        .req_in(req[W-1 : W-ENCODER_INPUT_WIDTH]), // Connect the upper bits of the top-level input
        .grant_out(grant)                          // Connect the submodule's output to the top-level grant
    );

    // Note: Original code contained unused logic (wires l1, l2 and their assignments)
    // which did not contribute to the 'grant' output. This dead code has been
    // removed in this refactored version for improved clarity and potential PPA benefits.

endmodule

// Submodule: priority_encoder_4bit_top3
// This module implements a dedicated 4-bit priority encoder logic.
// It takes a 4-bit input and outputs a 3-bit grant.
// The priority is from MSB (bit 3) down to LSB (bit 0), but only bits 3, 2, and 1
// are considered for generating a non-zero grant.
// The grant value indicates the index (plus an offset) of the highest priority bit set.
// - If req_in[3] is high, grant is 7 (binary 111).
// - Else if req_in[2] is high, grant is 6 (binary 110).
// - Else if req_in[1] is high, grant is 5 (binary 101).
// - If none of the above are high (including if only req_in[0] is high), grant is 0 (binary 000).
module priority_encoder_4bit_top3 #(
    parameter W_IN = 4,  // Input width (expected 4 bits for req_in[3:0])
    parameter W_OUT = 3  // Output width (expected 3 bits for grant value 0-7)
) (
    input [W_IN-1:0] req_in,      // 4-bit input slice to be encoded
    output [W_OUT-1:0] grant_out  // 3-bit priority encoded output grant
);

    // Ensure parameters match expected values for correct operation
    // Synthesis tools may ignore these checks, but they serve as documentation/assertion
    // `ifdef SYNTHESIS
    // initial begin
    //     if (W_IN != 4) $error("priority_encoder_4bit_top3 expects W_IN=4");
    //     if (W_OUT != 3) $error("priority_encoder_4bit_top3 expects W_OUT=3");
    // end
    // `endif

    // Combinatorial logic for priority encoding
    // Uses a ternary operator chain (priority structure) to determine grant_out
    // based on the highest priority bit set in req_in[3:1].
    assign grant_out = req_in[3] ? {W_OUT{1'b1}} : // If bit 3 is high, grant is all 1s (7)
                       req_in[2] ? 3'h6        : // Else if bit 2 is high, grant is 6
                       req_in[1] ? 3'h5        : // Else if bit 1 is high, grant is 5
                                   {W_OUT{1'b0}}; // Otherwise (including if only bit 0 is high or no bits high), grant is all 0s (0)

endmodule