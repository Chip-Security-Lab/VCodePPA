//SystemVerilog
module sr_latch (
    input wire s,
    input wire r,
    output reg q
);
    // IEEE 1364-2005 Verilog standard
    
    always @(*) begin
        case ({s, r})
            2'b10: q <= 1'b1;  // Set state
            2'b01: q <= 1'b0;  // Reset state
            // 2'b00 and 2'b11 maintain previous state (no assignment)
            default: ; // No action, maintain previous state
        endcase
    end
endmodule