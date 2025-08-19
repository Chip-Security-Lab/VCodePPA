//SystemVerilog
module dual_clock_gate (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire sel,
    output wire gated_clk
);
    // Internal synchronization signals
    wire sync_sel;
    wire safe_clk_out;
    
    // Synchronize selection signal to reduce metastability
    sel_synchronizer sel_sync_inst (
        .clk       (fast_clk),
        .async_sel (sel),
        .sync_sel  (sync_sel)
    );
    
    // Glitch-free clock selection core
    glitch_free_clock_mux clock_mux_inst (
        .fast_clock (fast_clk),
        .slow_clock (slow_clk),
        .select     (sync_sel),
        .out_clock  (safe_clk_out)
    );
    
    // Optional output buffer to improve drive strength
    clock_buffer out_buffer (
        .clk_in  (safe_clk_out),
        .clk_out (gated_clk)
    );
endmodule

module sel_synchronizer (
    input  wire clk,
    input  wire async_sel,
    output reg  sync_sel
);
    // Two-stage synchronizer to reduce metastability
    reg meta_stage;
    
    always @(posedge clk) begin
        meta_stage <= async_sel;
        sync_sel   <= meta_stage;
    end
endmodule

module glitch_free_clock_mux (
    input  wire fast_clock,
    input  wire slow_clock,
    input  wire select,
    output wire out_clock
);
    // Internal signals for glitch-free switching
    reg  fast_gate_n;
    reg  slow_gate_n;
    wire fast_gated;
    wire slow_gated;
    
    // Control logic for glitch-free switching
    always @(negedge fast_clock) begin
        fast_gate_n <= select;
    end
    
    always @(negedge slow_clock) begin
        slow_gate_n <= ~select;
    end
    
    // Gate each clock with its enable signal
    assign fast_gated = fast_clock & ~fast_gate_n;
    assign slow_gated = slow_clock & ~slow_gate_n;
    
    // Safe clock combining
    assign out_clock = fast_gated | slow_gated;
    
    // Synthesis attributes
    /* synthesis clock_mux */
    /* synthesis preserve_for_timing */
endmodule

module clock_buffer (
    input  wire clk_in,
    output wire clk_out
);
    // Non-inverting buffer with drive strength control
    assign clk_out = clk_in;
    
    // Synthesis attributes for clock buffer
    /* synthesis clock_buffer */
    /* synthesis dont_touch */
endmodule