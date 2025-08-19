//SystemVerilog
module d_latch_sync_rst (
    input wire d,
    input wire enable,
    input wire rst,      // Active high reset
    output reg q
);
    // Control logic using case statement to improve timing and reduce logic levels
    always @* begin
        case ({rst, enable})
            2'b10, 2'b11: q = 1'b0;  // Reset takes precedence regardless of enable
            2'b01:        q = d;     // Update when enabled and not in reset
            2'b00:        q = q;     // Hold value when not enabled and not in reset
        endcase
    end
endmodule