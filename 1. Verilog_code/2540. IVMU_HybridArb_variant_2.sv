//SystemVerilog
// Top module
module IVMU_HybridArb #(parameter MODE=0) (
    input clk,
    input [3:0] req,
    output [1:0] grant, // Output representing the selected grant value
    output reg grant_valid, // Indicates when grant is valid
    input grant_ready // Indicates when the receiver is ready to accept grant
);

// Internal state for the granted value
reg [1:0] current_grant;

// Connect the internal state to the output grant
assign grant = current_grant;

// Signals for the 4-bit CLA
wire [3:0] cla_A_in;
wire [3:0] cla_B_in;
wire cla_cin_in;
wire [3:0] cla_sum_out;
wire cla_cout_out;

// Inputs to the 4-bit CLA for the current_grant + 1 operation (used in RR mode calculation)
// We are adding 1 (4'b0001) to the 2-bit current_grant value (padded to 4 bits)
assign cla_A_in = {2'b00, current_grant}; // Use the currently offered grant for calculation
assign cla_B_in = 4'b0001;
assign cla_cin_in = 1'b0; // No initial carry-in for increment

// Instantiate the 4-bit Carry-Lookahead Adder
cla_4bit adder_inst (
    .A(cla_A_in),
    .B(cla_B_in),
    .cin(cla_cin_in),
    .S(cla_sum_out),
    .cout(cla_cout_out)
);

// The next potential value for grant from the CLA (used in RR mode calculation)
wire [1:0] next_grant_val_cla = cla_sum_out[1:0];

// RR wrap-around logic based on the currently offered grant
wire [1:0] next_grant_rr_candidate = (current_grant == 2'b11) ? 2'b00 : next_grant_val_cla;

// Fixed mode logic calculates the grant based on req priority
wire [1:0] fixed_next_grant_candidate = (req[0]) ? 2'b00 :
                                        (req[1]) ? 2'b01 :
                                        2'b10; // Default to 2 if req[0] and req[1] are 0

// The next grant candidate value based on the mode
wire [1:0] next_grant_candidate = (MODE == 1) ? fixed_next_grant_candidate : next_grant_rr_candidate;

always @(posedge clk) begin
    // Determine if the module is ready to present a new grant value
    // This happens when the previous handshake completed OR when no grant is currently being offered
    logic ready_to_present_new = (grant_valid && grant_ready) || !grant_valid;

    // Determine if a grant is available to be offered based on the mode and requests
    // In fixed mode, a grant is available if any request is active.
    // In round-robin mode, a grant is always conceptually available (the arbiter continuously cycles).
    logic grant_available = (MODE == 1) ? (|req) : 1'b1;

    if (ready_to_present_new) begin
        if (grant_available) begin
            // A new grant is available and the module is ready to present it.
            current_grant <= next_grant_candidate;
            grant_valid <= 1'b1; // Assert valid for the new grant
        end else begin
            // Fixed mode, no requests active. Cannot offer a grant.
            // Deassert valid. current_grant value is irrelevant when valid is low.
            grant_valid <= 1'b0;
        end
    end
    // else (grant_valid && !grant_ready): Hold the current grant and valid state, waiting for ready.
end

// Initialize registers on reset (implicit power-on reset)
initial begin
    current_grant = 2'b00;
    grant_valid = 1'b0;
end

endmodule

// Sub-module: 4-bit Carry-Lookahead Adder
module cla_4bit (
    input [3:0] A,
    input [3:0] B,
    input cin,
    output [3:0] S,
    output cout
);

wire [3:0] P; // Propagate signals
wire [3:0] G; // Generate signals
wire [3:1] C; // Internal carry signals (C1, C2, C3)

// Generate P and G signals for each bit
assign P = A ^ B;
assign G = A & B;

// Carry Lookahead Logic
// C1 = G0 + P0*cin
assign C[1] = G[0] | (P[0] & cin);
// C2 = G1 + P1*C1 = G1 + P1*G0 + P1*P0*cin
assign C[2] = G[1] | (P[1] & C[1]);
// C3 = G2 + P2*C2 = G2 + P2*G1 + P2*P1*G0 + P2*P1*P0*cin
assign C[3] = G[2] | (P[2] & C[2]);
// C4 (cout) = G3 + P3*C3 = G3 + P3*G2 + P3*P2*G1 + P3*P2*P1*G0 + P3*P2*P1*P0*cin
assign cout = G[3] | (P[3] & C[3]); // Corrected cout calculation

// Sum generation
// S_i = P_i ^ C_i (where C_0 = cin)
assign S[0] = P[0] ^ cin;
assign S[1] = P[1] ^ C[1];
assign S[2] = P[2] ^ C[2];
assign S[3] = P[3] ^ C[3];

endmodule