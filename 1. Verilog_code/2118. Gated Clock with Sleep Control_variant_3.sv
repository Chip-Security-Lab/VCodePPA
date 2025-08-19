//SystemVerilog (IEEE 1364-2005)
//===========================================================================
// Top Module - Clock Gating with Sleep Control (Optimized with Register Retiming)
//===========================================================================
module gated_clk_sleep(
    input  wire clk_src,
    input  wire sleep,
    input  wire enable,
    output wire gated_clk
);
    // Internal signals
    wire enable_latch_comb;
    wire sleep_sync;
    
    // Instantiate sequential logic module (moved register earlier in pipeline)
    latch_control seq_logic (
        .clk_src        (clk_src),
        .sleep          (sleep),
        .enable         (enable),
        .enable_latch   (enable_latch_comb),
        .sleep_sync     (sleep_sync)
    );

    // Instantiate combinational logic module (simplified)
    clock_gate comb_logic (
        .clk_src        (clk_src),
        .sleep_sync     (sleep_sync),
        .enable_latch   (enable_latch_comb),
        .gated_clk      (gated_clk)
    );
endmodule

//===========================================================================
// Sequential Logic Module (Retimed)
//===========================================================================
module latch_control (
    input  wire clk_src,
    input  wire sleep,
    input  wire enable,
    output reg  enable_latch,
    output reg  sleep_sync
);
    // Register sleep signal (register retiming - moving register earlier)
    always @(negedge clk_src or posedge sleep) begin
        if (sleep)
            sleep_sync <= 1'b1;
        else
            sleep_sync <= sleep;
    end
    
    // Latch enable signal on negative edge (sequential logic)
    always @(negedge clk_src or posedge sleep) begin
        if (sleep)
            enable_latch <= 1'b0;
        else
            enable_latch <= enable;
    end
endmodule

//===========================================================================
// Combinational Logic Module (Simplified)
//===========================================================================
module clock_gate (
    input  wire clk_src,
    input  wire sleep_sync,
    input  wire enable_latch,
    output wire gated_clk
);
    // Gate the clock (pure combinational logic - simplified critical path)
    assign gated_clk = clk_src & enable_latch & ~sleep_sync;
endmodule