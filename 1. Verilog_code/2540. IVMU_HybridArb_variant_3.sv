//SystemVerilog
// Module for fixed priority arbitration logic
// Calculates the next grant value based on request inputs with fixed priority (0 > 1 > 2)
module ivmu_fixed_priority_arb (
    input [3:0] req,              // Request inputs (req[0] highest priority)
    output [1:0] next_grant_fixed // Calculated next grant value (combinational)
);

    // Logic: If req[0] is high, grant 0. Else if req[1] is high, grant 1. Else grant 2.
    // This matches the original code's fixed priority logic for MODE=1.
    assign next_grant_fixed = (req[0] ? 2'd0 : (req[1] ? 2'd1 : 2'd2));

endmodule

// Module for round-robin arbitration logic
// Calculates the next grant value based on the current grant value
module ivmu_round_robin_arb (
    input [1:0] current_grant, // Current grant value from the register
    output [1:0] next_grant_rr  // Calculated next grant value (combinational)
);

    // Logic: If current grant is 3, next grant is 0. Otherwise, increment current grant.
    // This matches the original code's round-robin logic for MODE=0.
    assign next_grant_rr = (current_grant == 2'd3) ? 2'd0 : current_grant + 2'd1;

endmodule

// Top module: Hybrid Arbiter combining fixed priority and round-robin
// Selects the arbitration mode based on the parameter MODE and registers the result
module IVMU_HybridArb #(parameter MODE=0) (
    input clk,       // Clock signal for synchronous operation
    input [3:0] req, // Request inputs for arbitration
    output reg [1:0] grant // Output grant value (registered)
);

    // Wires to hold the calculated next grant values from the sub-modules
    wire [1:0] next_grant_fixed_w;
    wire [1:0] next_grant_rr_w;

    // Instantiate the fixed priority arbiter sub-module
    ivmu_fixed_priority_arb u_fixed_arb (
        .req(req),                      // Connect requests
        .next_grant_fixed(next_grant_fixed_w) // Output next grant for fixed mode
    );

    // Instantiate the round-robin arbiter sub-module
    // This module needs the current value of the 'grant' register to calculate the next state
    ivmu_round_robin_arb u_rr_arb (
        .current_grant(grant),          // Connect current grant value (feedback)
        .next_grant_rr(next_grant_rr_w) // Output next grant for round-robin mode
    );

    // Multiplexer to select the next grant value based on the MODE parameter
    // If MODE is 1, select fixed priority output. If MODE is 0, select round-robin output.
    wire [1:0] next_grant_mux_w;
    assign next_grant_mux_w = (MODE ? next_grant_fixed_w : next_grant_rr_w);

    // Register the selected next grant value on the positive clock edge
    // This implements the sequential behavior of the arbiter output
    always @(posedge clk) begin
        grant <= next_grant_mux_w;
    end

endmodule