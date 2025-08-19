//SystemVerilog
// Top-level module for 4-bit LFSR-based RNG
module rng_lfsr_12(
    input           clk,
    input           en,
    output [3:0]    rand_out
);

    wire [3:0] lfsr_state;
    wire       feedback;

    // LFSR Feedback Calculation Module
    lfsr_feedback #(
        .WIDTH(4)
    ) u_lfsr_feedback (
        .state_in(lfsr_state),
        .feedback_out(feedback)
    );

    // LFSR State Register Module
    lfsr_state_reg #(
        .WIDTH(4),
        .INIT_STATE(4'b1010)
    ) u_lfsr_state_reg (
        .clk(clk),
        .en(en),
        .feedback(feedback),
        .state_out(lfsr_state)
    );

    assign rand_out = lfsr_state;

endmodule

//------------------------------------------------------------------------------
// LFSR Feedback Calculation Module
// Calculates the feedback bit for the LFSR based on the tap positions.
//------------------------------------------------------------------------------
module lfsr_feedback #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] state_in,
    output             feedback_out
);
    // For 4-bit LFSR, taps at bit 3 and bit 2 (state_in[3] ^ state_in[2])
    assign feedback_out = state_in[3] ^ state_in[2];
endmodule

//------------------------------------------------------------------------------
// LFSR State Register Module
// Holds the current state of the LFSR and updates it on each clock cycle.
//------------------------------------------------------------------------------
module lfsr_state_reg #(
    parameter WIDTH = 4,
    parameter [WIDTH-1:0] INIT_STATE = 4'b0001
)(
    input                   clk,
    input                   en,
    input                   feedback,
    output reg [WIDTH-1:0]  state_out
);
    always @(posedge clk) begin
        if (en)
            state_out <= {state_out[WIDTH-2:0], feedback};
        else
            state_out <= state_out;
    end

    // Asynchronous reset to initial state on power-up
    initial begin
        state_out = INIT_STATE;
    end
endmodule