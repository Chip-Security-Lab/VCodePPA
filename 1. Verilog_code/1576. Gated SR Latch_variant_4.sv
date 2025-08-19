//SystemVerilog
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
            case ({s, r})
                2'b10: q = 1'b1;  // Set
                2'b01: q = 1'b0;  // Reset
                2'b00: q = q;     // Hold state
                2'b11: q = q;     // Invalid/metastable state
                default: q = q;   // Default case
            endcase
        end
    end
endmodule