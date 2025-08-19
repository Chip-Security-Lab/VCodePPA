//SystemVerilog
module AsyncIVMU_vr (
    input clk,
    input rst_n,
    input [7:0] int_lines,
    input [7:0] int_mask,

    output [31:0] vector_out,
    output vector_out_valid,
    input vector_out_ready,

    output int_active,
    output int_active_valid,
    input int_active_ready // This input is included as requested but is assumed tied to vector_out_ready or unused in this single-handshake implementation.
);

    // Internal combinatorial signals
    reg [31:0] vector_map [0:7];
    wire [7:0] masked_ints;
    reg [2:0] active_int_comb; // Combinatorial index
    wire [31:0] vector_out_comb; // Combinatorial vector output
    wire int_active_comb;       // Combinatorial active flag
    integer i;                  // Loop variable

    // Registered output signals for Valid-Ready
    reg [31:0] vector_out_reg;
    reg vector_out_valid_reg;
    reg int_active_reg;
    reg int_active_valid_reg;

    // --- Combinatorial Logic (Calculates next potential output) ---
    initial begin // vector_map initialization
        for (i = 0; i < 8; i = i + 1)
            vector_map[i] = 32'h2000_0000 + (i * 4);
    end

    assign masked_ints = int_lines & ~int_mask;
    assign int_active_comb = |masked_ints; // Combinatorial active flag

    // Combinatorial priority encoder
    always @(*) begin
        active_int_comb = 0; // Default
        // Priority from 7 down to 0
        for (i = 7; i >= 0; i = i - 1) begin
            if (masked_ints[i]) begin
                active_int_comb = i[2:0];
                // Synthesis tools typically handle this as a priority encoder
            end
        end
    end

    assign vector_out_comb = vector_map[active_int_comb]; // Combinatorial vector output


    // --- Sequential Logic (Registers outputs and valid signals) ---
    // Implements a state machine for the Valid-Ready handshake
    // State is implicitly held in vector_out_valid_reg (0=IDLE, 1=VALID)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_out_reg <= 32'b0;
            vector_out_valid_reg <= 1'b0; // Start in IDLE state
            int_active_reg <= 1'b0;
            int_active_valid_reg <= 1'b0; // Follows vector_out_valid_reg
        end else begin
            // Calculate next state/output values
            reg next_vector_out_valid;
            reg [31:0] next_vector_out;
            reg next_int_active;

            // Default: hold current state/output
            next_vector_out_valid = vector_out_valid_reg;
            next_vector_out = vector_out_reg;
            next_int_active = int_active_reg;

            // Flattened state transition logic using combined conditions
            // Transition to VALID or Stay VALID with new data
            // Condition: (Current state is IDLE OR Receiver is ready) AND Input is active
            if ((!vector_out_valid_reg || vector_out_ready) && int_active_comb) begin
                next_vector_out_valid = 1'b1;
                next_vector_out = vector_out_comb;
                next_int_active = int_active_comb; // Keep int_active high
            end
            // Transition from VALID to IDLE
            // Condition: Current state is VALID AND Receiver is ready AND Input becomes inactive
            else if (vector_out_valid_reg && vector_out_ready && !int_active_comb) begin
                next_vector_out_valid = 1'b0;
                // Optional: clear data registers when invalid
                next_vector_out = 32'b0;
                next_int_active = 1'b0; // Clear int_active
            end
            // All other cases (IDLE->IDLE, VALID->VALID hold) are covered by the default assignments.

            // Update registers
            vector_out_valid_reg <= next_vector_out_valid;
            vector_out_reg <= next_vector_out;
            int_active_reg <= next_int_active;
            int_active_valid_reg <= next_vector_out_valid; // int_active_valid follows vector_out_valid
        end
    end

    // Assign registered outputs to module outputs
    assign vector_out = vector_out_reg;
    assign vector_out_valid = vector_out_valid_reg;
    assign int_active = int_active_reg;
    assign int_active_valid = int_active_valid_reg;

endmodule