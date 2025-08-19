//SystemVerilog
//===========================================================================
// Top-level Watchdog Reset Synchronizer Module
//===========================================================================
module watchdog_rst_sync (
    input  wire clk,            // System clock
    input  wire ext_rst_n,      // External reset (active low)
    input  wire watchdog_trigger, // Watchdog trigger signal
    output wire combined_rst_n  // Combined reset output (active low)
);
    // Internal signals
    wire ext_rst_n_sync;     // Synchronized external reset
    wire watchdog_rst_n;     // Watchdog reset signal

    // External reset synchronizer instance
    ext_rst_synchronizer u_ext_rst_sync (
        .clk        (clk),
        .ext_rst_n  (ext_rst_n),
        .rst_n_sync (ext_rst_n_sync)
    );

    // Watchdog reset controller instance
    watchdog_rst_controller u_watchdog_ctrl (
        .clk             (clk),
        .watchdog_trigger(watchdog_trigger),
        .watchdog_rst_n  (watchdog_rst_n)
    );

    // Reset combiner instance
    reset_combiner u_rst_combiner (
        .clk            (clk),
        .ext_rst_n_sync (ext_rst_n_sync),
        .watchdog_rst_n (watchdog_rst_n),
        .combined_rst_n (combined_rst_n)
    );

endmodule

//===========================================================================
// External Reset Synchronizer Module
//===========================================================================
module ext_rst_synchronizer #(
    parameter SYNC_STAGES = 4  // Increased number of synchronization stages
) (
    input  wire clk,          // System clock
    input  wire ext_rst_n,    // External reset (active low)
    output wire rst_n_sync    // Synchronized reset output
);
    // Synchronizer flip-flop chain
    reg [SYNC_STAGES-1:0] sync_chain;

    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            sync_chain <= {SYNC_STAGES{1'b0}};
        else
            sync_chain <= {sync_chain[SYNC_STAGES-2:0], 1'b1};
    end

    // Output assignment
    assign rst_n_sync = sync_chain[SYNC_STAGES-1];

endmodule

//===========================================================================
// Watchdog Reset Controller Module
//===========================================================================
module watchdog_rst_controller (
    input  wire clk,             // System clock
    input  wire watchdog_trigger, // Watchdog trigger signal
    output wire watchdog_rst_n   // Watchdog reset output (active low)
);
    // Multi-stage pipeline registers for improved timing
    reg watchdog_trigger_stage1;
    reg watchdog_trigger_stage2;
    reg watchdog_trigger_stage3;
    reg watchdog_rst_n_stage1;
    reg watchdog_rst_n_stage2;
    reg watchdog_rst_n_final;

    // Pipeline stage 1: Input capture
    always @(posedge clk) begin
        watchdog_trigger_stage1 <= watchdog_trigger;
    end

    // Pipeline stage 2: Trigger processing
    always @(posedge clk) begin
        watchdog_trigger_stage2 <= watchdog_trigger_stage1;
        watchdog_trigger_stage3 <= watchdog_trigger_stage2;
    end

    // Pipeline stage 3: Reset generation
    always @(posedge clk) begin
        watchdog_rst_n_stage1 <= watchdog_trigger_stage3 ? 1'b0 : 1'b1;
    end

    // Pipeline stage 4: Reset stabilization
    always @(posedge clk) begin
        watchdog_rst_n_stage2 <= watchdog_rst_n_stage1;
        watchdog_rst_n_final <= watchdog_rst_n_stage2;
    end

    // Output assignment
    assign watchdog_rst_n = watchdog_rst_n_final;

endmodule

//===========================================================================
// Reset Combiner Module with LUT-based implementation
//===========================================================================
module reset_combiner (
    input  wire clk,            // System clock
    input  wire ext_rst_n_sync, // Synchronized external reset
    input  wire watchdog_rst_n, // Watchdog reset signal
    output wire combined_rst_n  // Combined reset output (active low)
);
    // Pipeline registers for improved timing
    reg ext_rst_n_sync_stage1;
    reg watchdog_rst_n_stage1;
    reg combined_rst_n_reg;

    // LUT-based combiner using 8-bit ROM
    reg [7:0] lut_reset_combiner;
    reg [2:0] lut_index;
    
    // Initialize LUT (equivalent to AND operation but enables future customization)
    initial begin
        lut_reset_combiner[0] = 1'b0; // 000: both resets active
        lut_reset_combiner[1] = 1'b0; // 001: ext_rst active, watchdog inactive
        lut_reset_combiner[2] = 1'b0; // 010: ext_rst inactive, watchdog active
        lut_reset_combiner[3] = 1'b1; // 011: both resets inactive
        lut_reset_combiner[4] = 1'b0; // 100: ext_rst_stage2 active, watchdog active
        lut_reset_combiner[5] = 1'b0; // 101: ext_rst_stage2 active, watchdog inactive
        lut_reset_combiner[6] = 1'b0; // 110: ext_rst_stage2 inactive, watchdog active
        lut_reset_combiner[7] = 1'b1; // 111: both resets inactive
    end

    // Input capture
    always @(posedge clk) begin
        ext_rst_n_sync_stage1 <= ext_rst_n_sync;
        watchdog_rst_n_stage1 <= watchdog_rst_n;
    end

    // LUT index computation
    always @(posedge clk) begin
        lut_index <= {1'b1, ext_rst_n_sync_stage1, watchdog_rst_n_stage1};
    end

    // LUT-based reset combining
    always @(posedge clk) begin
        combined_rst_n_reg <= lut_reset_combiner[lut_index];
    end

    // Output assignment
    assign combined_rst_n = combined_rst_n_reg;

endmodule