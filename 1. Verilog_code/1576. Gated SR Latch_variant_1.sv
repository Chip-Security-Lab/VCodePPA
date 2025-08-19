//SystemVerilog
module gated_sr_latch (
    input wire s,        // Set
    input wire r,        // Reset
    input wire gate,     // Enable
    output reg q,
    output wire q_n      // Complementary output
);

    // Input gating stage
    wire s_gated;
    wire r_gated;
    assign s_gated = s & gate;
    assign r_gated = r & gate;

    // State transition logic
    wire next_state;
    assign next_state = (s_gated & ~r_gated) ? 1'b1 :
                       (~s_gated & r_gated) ? 1'b0 :
                       q;  // Hold state when s=0, r=0

    // State storage
    always @* begin
        q = next_state;
    end

    // Output stage
    assign q_n = ~q;

endmodule