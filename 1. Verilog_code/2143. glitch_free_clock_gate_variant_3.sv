//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: glitch_free_clock_gate_top.v
// Author: FPGA Specialist
// Description: Top-level module for glitch-free clock gating
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module glitch_free_clock_gate (
    input  wire clk_in,   // Input clock
    input  wire enable,   // Enable signal
    input  wire rst_n,    // Active-low reset
    output wire clk_out   // Gated clock output
);

    // Internal signals
    wire enable_synced;
    
    // Instantiate synchronizer sub-module
    enable_synchronizer u_enable_sync (
        .clk_in     (clk_in),
        .rst_n      (rst_n),
        .enable_in  (enable),
        .enable_out (enable_synced)
    );
    
    // Instantiate clock gating cell
    clock_gate_cell u_clock_gate (
        .clk_in     (clk_in),
        .enable     (enable_synced),
        .clk_out    (clk_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Enable signal synchronizer sub-module - optimized with backward retiming
///////////////////////////////////////////////////////////////////////////////

module enable_synchronizer (
    input  wire clk_in,     // Input clock
    input  wire rst_n,      // Active-low reset
    input  wire enable_in,  // Input enable signal
    output reg  enable_out  // Synchronized enable signal (now registered output)
);
    
    // Single synchronization flip-flop (reduced from two-stage to improve timing)
    reg enable_ff1;
    
    // Single-FF synchronizer with output register moved before logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_ff1 <= 1'b0;
        end else begin
            enable_ff1 <= enable_in;
        end
    end
    
    // Output register (moved backward from the clock_gate_cell)
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_out <= 1'b0;
        end else begin
            enable_out <= enable_ff1;
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Clock gating cell sub-module - optimized with register retiming
///////////////////////////////////////////////////////////////////////////////

module clock_gate_cell (
    input  wire clk_in,   // Input clock
    input  wire enable,   // Synchronized enable signal
    output wire clk_out   // Gated clock output
);
    
    // Glitch-free clock gating with enable directly applied
    // The synchronization register has been moved to the enable_synchronizer module
    assign clk_out = clk_in & enable;
    
endmodule