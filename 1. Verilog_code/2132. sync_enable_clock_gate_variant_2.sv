//SystemVerilog
module sync_enable_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire enable,
    output wire clk_out
);
    reg enable_latch;
    reg enable_ff;
    
    // Capture enable signal in a flip-flop first (register moved forward)
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            enable_ff <= 1'b0;
        else
            enable_ff <= enable;
    end
    
    // Latch to prevent glitches - only opens when clock is low
    always @(*) begin
        if (!clk_in)
            enable_latch = enable_ff;
    end
    
    // Clock gating with latch-based implementation for glitch-free operation
    assign clk_out = clk_in & enable_latch;
endmodule