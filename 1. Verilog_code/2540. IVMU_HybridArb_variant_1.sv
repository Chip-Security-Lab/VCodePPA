//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

//------------------------------------------------------------------------------
// Top level module for Hybrid Arbiter
// Selects between Fixed Priority and Round Robin arbitration based on MODE.
//------------------------------------------------------------------------------
module IVMU_HybridArb #(parameter MODE=0) (
    input wire clk,
    input wire [3:0] req,
    output reg [1:0] grant
);

    // Internal wires to hold the next grant values computed by sub-modules
    wire [1:0] grant_fixed_next_w; // Next grant value from fixed priority logic
    wire [1:0] grant_rr_next_w;    // Next grant value from round robin logic

    // Instantiate the Fixed Priority Arbiter sub-module
    // This module computes the next grant based on fixed priority rules (combinatorial)
    fixed_arbiter u_fixed_arbiter (
        .req(req),                          // Connect request inputs
        .grant_fixed_next(grant_fixed_next_w) // Output wire for fixed priority next grant
    );

    // Instantiate the Round Robin Arbiter sub-module
    // This module computes the next grant based on the current grant (combinatorial)
    round_robin_arbiter u_round_robin_arbiter (
        .current_grant_rr(grant),       // Connect the current registered grant (state)
        .grant_rr_next(grant_rr_next_w) // Output wire for round robin next grant
    );

    // Registered logic to select and update the grant based on the mode
    // This block acts as the state element (register) and the mode selector
    always @(posedge clk) begin
        if (MODE == 1) begin // Mode 1: Fixed Priority
            // Assign the next grant value computed by the fixed priority arbiter
            grant <= grant_fixed_next_w;
        end else begin // Mode 0: Round Robin (or any other value)
            // Assign the next grant value computed by the round robin arbiter
            grant <= grant_rr_next_w;
        end
    end

endmodule

//------------------------------------------------------------------------------
// Sub-module for Fixed Priority Arbitration Logic
// Computes the next grant based on fixed priority rules.
// This module is combinatorial.
//------------------------------------------------------------------------------
module fixed_arbiter (
    input wire [3:0] req,              // Request inputs
    output wire [1:0] grant_fixed_next // Computed next grant value
);

    // Assign the next grant based on fixed priority:
    // req[0] has highest priority (grant 0)
    // req[1] has second highest priority (grant 1)
    // req[2] has third highest priority (grant 2)
    // req[3] has lowest priority (grant 3)
    // If no request, grant 3 (or default) - adjusted to cover 4 reqs
    assign grant_fixed_next = (req[0] ? 2'd0 : req[1] ? 2'd1 : req[2] ? 2'd2 : 2'd3);

endmodule

//------------------------------------------------------------------------------
// Sub-module for Round Robin Arbitration Logic
// Computes the next grant based on the current grant value (round robin).
// This module is combinatorial.
//------------------------------------------------------------------------------
module round_robin_arbiter (
    input wire [1:0] current_grant_rr, // Current grant value (state)
    output wire [1:0] grant_rr_next     // Computed next grant value
);

    // Assign the next grant based on round robin logic:
    // Increment the current grant, wrapping around from 3 to 0.
    assign grant_rr_next = (current_grant_rr == 2'd3) ? 2'd0 : current_grant_rr + 2'd1;

endmodule

`default_nettype wire