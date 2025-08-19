//SystemVerilog
module sr_flip_flop (
    input wire clk,
    input wire s,
    input wire r,
    output reg q
);
    // Registered inputs to improve timing
    reg s_reg, r_reg;
    
    // Register the inputs first
    always @(posedge clk) begin
        s_reg <= s;
        r_reg <= r;
    end
    
    // SR flip-flop logic using registered inputs
    always @(posedge clk) begin
        case ({s_reg, r_reg})
            2'b00: q <= q;      // No change
            2'b01: q <= 1'b0;   // Reset
            2'b10: q <= 1'b1;   // Set
            2'b11: q <= 1'bx;   // Invalid - undefined
        endcase
    end
endmodule