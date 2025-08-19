//SystemVerilog
// Top-level module: Configurable 16-bit LFSR with polynomial tap control
module config_poly_lfsr (
    input  wire        clock,
    input  wire        reset,
    input  wire [15:0] polynomial,  // Configurable taps
    output wire [15:0] rand_out
);

    wire        feedback_signal;
    wire [15:0] lfsr_next;
    reg  [15:0] lfsr_reg;

    // Feedback calculation submodule
    lfsr_feedback #(
        .LFSR_WIDTH(16)
    ) u_lfsr_feedback (
        .lfsr_state  (lfsr_reg),
        .poly_taps   (polynomial),
        .feedback_out(feedback_signal)
    );

    // LFSR register update submodule
    lfsr_register #(
        .LFSR_WIDTH(16)
    ) u_lfsr_register (
        .clock      (clock),
        .reset      (reset),
        .feedback   (feedback_signal),
        .lfsr_out   (lfsr_reg)
    );

    assign rand_out = lfsr_reg;

endmodule

//------------------------------------------------------------------------------
// Submodule: lfsr_feedback
// Description: Computes the feedback bit for a configurable LFSR using a balanced XOR tree
//------------------------------------------------------------------------------
module lfsr_feedback #(
    parameter LFSR_WIDTH = 16
)(
    input  wire [LFSR_WIDTH-1:0] lfsr_state,
    input  wire [LFSR_WIDTH-1:0] poly_taps,
    output wire                  feedback_out
);

    wire [LFSR_WIDTH-1:0] tap_and;
    wire [7:0]  tap_xor_stage2;
    wire [3:0]  tap_xor_stage3;
    wire [1:0]  tap_xor_stage4;

    // Stage 1: AND operation between LFSR state and polynomial taps
    assign tap_and = lfsr_state & poly_taps;

    // Stage 2: XOR pairs for balanced tree
    assign tap_xor_stage2[7] = tap_and[15] ^ tap_and[14];
    assign tap_xor_stage2[6] = tap_and[13] ^ tap_and[12];
    assign tap_xor_stage2[5] = tap_and[11] ^ tap_and[10];
    assign tap_xor_stage2[4] = tap_and[9]  ^ tap_and[8];
    assign tap_xor_stage2[3] = tap_and[7]  ^ tap_and[6];
    assign tap_xor_stage2[2] = tap_and[5]  ^ tap_and[4];
    assign tap_xor_stage2[1] = tap_and[3]  ^ tap_and[2];
    assign tap_xor_stage2[0] = tap_and[1]  ^ tap_and[0];

    // Stage 3: XOR pairs
    assign tap_xor_stage3[3] = tap_xor_stage2[7] ^ tap_xor_stage2[6];
    assign tap_xor_stage3[2] = tap_xor_stage2[5] ^ tap_xor_stage2[4];
    assign tap_xor_stage3[1] = tap_xor_stage2[3] ^ tap_xor_stage2[2];
    assign tap_xor_stage3[0] = tap_xor_stage2[1] ^ tap_xor_stage2[0];

    // Stage 4: XOR pairs
    assign tap_xor_stage4[1] = tap_xor_stage3[3] ^ tap_xor_stage3[2];
    assign tap_xor_stage4[0] = tap_xor_stage3[1] ^ tap_xor_stage3[0];

    // Final feedback calculation
    assign feedback_out = tap_xor_stage4[1] ^ tap_xor_stage4[0];

endmodule

//------------------------------------------------------------------------------
// Submodule: lfsr_register
// Description: 16-bit LFSR shift register with synchronous reset and feedback input
//------------------------------------------------------------------------------
module lfsr_register #(
    parameter LFSR_WIDTH = 16
)(
    input  wire                  clock,
    input  wire                  reset,
    input  wire                  feedback,
    output reg  [LFSR_WIDTH-1:0] lfsr_out
);

    always @(posedge clock) begin
        if (reset)
            lfsr_out <= {{(LFSR_WIDTH-1){1'b0}}, 1'b1};  // LFSR seed: 0...01
        else
            lfsr_out <= {lfsr_out[LFSR_WIDTH-2:0], feedback};
    end

endmodule