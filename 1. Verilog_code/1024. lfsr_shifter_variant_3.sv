//SystemVerilog
// Top-level LFSR Shifter Module
module lfsr_shifter (
    input clk,
    input rst,
    output [6:0] prbs
);

    wire [6:0] lfsr_state;
    wire feedback_bit;
    wire [6:0] next_lfsr_state;

    // LFSR State Register Module
    lfsr_register u_lfsr_register (
        .clk(clk),
        .rst(rst),
        .next_state(next_lfsr_state),
        .current_state(lfsr_state)
    );

    // LFSR Feedback Logic Module
    lfsr_feedback u_lfsr_feedback (
        .lfsr_state(lfsr_state),
        .feedback(feedback_bit)
    );

    // LFSR Next State Calculation Module
    lfsr_next_state u_lfsr_next_state (
        .lfsr_state(lfsr_state),
        .feedback(feedback_bit),
        .next_state(next_lfsr_state)
    );

    // Output the next state as the PRBS output
    assign prbs = next_lfsr_state;

endmodule

// LFSR State Register Module
// Holds the current state of the LFSR and updates on each clock cycle
module lfsr_register (
    input clk,
    input rst,
    input [6:0] next_state,
    output reg [6:0] current_state
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= 7'b111_1111;
        else
            current_state <= next_state;
    end
endmodule

// LFSR Feedback Logic Module
// Calculates the feedback bit using specified taps (bit 6 and bit 4)
module lfsr_feedback (
    input [6:0] lfsr_state,
    output feedback
);
    assign feedback = lfsr_state[6] ^ lfsr_state[4];
endmodule

// LFSR Next State Calculation Module
// Computes the next state of LFSR using current state and feedback bit
module lfsr_next_state (
    input [6:0] lfsr_state,
    input feedback,
    output [6:0] next_state
);
    assign next_state = {lfsr_state[5:0], feedback};
endmodule