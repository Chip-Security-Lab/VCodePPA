module gated_sr_latch (
    input wire s,        // Set
    input wire r,        // Reset
    input wire gate,     // Enable
    output reg q,
    output wire q_n      // Complementary output
);
    assign q_n = ~q;
    
    always @* begin
        if (gate) begin
            if (s && !r)
                q = 1'b1;
            else if (!s && r)
                q = 1'b0;
            // s=0, r=0: hold state
            // s=1, r=1: invalid/metastable
        end
    end
endmodule