//SystemVerilog
module gated_clock_gen(
    input  wire master_clk,
    input  wire gate_enable,
    input  wire rst,
    output wire gated_clk
);
    // Enable latch for glitch-free clock gating
    reg latch_enable;
    
    // First pipeline stage - capture the enable signal
    always @(negedge master_clk or posedge rst)
        latch_enable <= rst ? 1'b0 : gate_enable;
    
    // Second pipeline stage - generate the gated clock
    // Using AND gate for clock gating
    assign gated_clk = master_clk & latch_enable;
endmodule