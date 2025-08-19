//SystemVerilog
module latch_based_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // Level-sensitive latch implementation for clock gating
    // Using transparent latch behavior when clock is low
    reg latch_out;
    
    // Latch implementation with negative level-sensitivity
    always @(clk_in or enable) begin
        if (!clk_in) begin
            latch_out <= enable;
        end
    end
    
    // Clock gating AND operation
    assign clk_out = clk_in & latch_out;
endmodule