//SystemVerilog
// Top-level module: Galois LFSR RNG with hierarchical structure
module galois_lfsr_rng (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    output wire [7:0] rand_data
);

    // Internal register to hold LFSR state
    reg [7:0] lfsr_state;

    // Wires for next state computation
    wire [7:0] lfsr_next_state;

    // LFSR Next State Computation Submodule
    lfsr_next_state_logic u_lfsr_next_state_logic (
        .current_state(lfsr_state),
        .next_state(lfsr_next_state)
    );

    // LFSR State Register Submodule
    lfsr_state_register u_lfsr_state_register (
        .clock(clock),
        .reset(reset),
        .enable(enable),
        .next_state(lfsr_next_state),
        .current_state(lfsr_state)
    );

    // Output assignment
    assign rand_data = lfsr_state;

endmodule

// -----------------------------------------------------------------------
// Submodule: LFSR Next State Logic
// Computes the next state of the 8-bit Galois LFSR based on the current state
// Simplified using Boolean algebra
// -----------------------------------------------------------------------
module lfsr_next_state_logic (
    input  wire [7:0] current_state,
    output wire [7:0] next_state
);
    // Galois LFSR feedback and shifting logic (simplified)
    assign next_state[0] = current_state[7];
    assign next_state[1] = current_state[0];
    // next_state[2] = current_state[1] ^ current_state[7]; (No further simplification)
    assign next_state[2] = (current_state[1] & ~current_state[7]) | (~current_state[1] & current_state[7]);
    // next_state[3] = current_state[2] ^ current_state[7]; (No further simplification)
    assign next_state[3] = (current_state[2] & ~current_state[7]) | (~current_state[2] & current_state[7]);
    assign next_state[4] = current_state[3];
    // next_state[5] = current_state[4] ^ current_state[7]; (No further simplification)
    assign next_state[5] = (current_state[4] & ~current_state[7]) | (~current_state[4] & current_state[7]);
    assign next_state[6] = current_state[5];
    assign next_state[7] = current_state[6];
endmodule

// -----------------------------------------------------------------------
// Submodule: LFSR State Register
// Synchronous register with reset and enable for LFSR state storage
// -----------------------------------------------------------------------
module lfsr_state_register (
    input  wire       clock,
    input  wire       reset,
    input  wire       enable,
    input  wire [7:0] next_state,
    output reg  [7:0] current_state
);
    always @(posedge clock) begin
        if (reset)
            current_state <= 8'h1;
        else if (enable)
            current_state <= next_state;
    end
endmodule