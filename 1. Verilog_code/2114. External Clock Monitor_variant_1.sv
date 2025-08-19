//SystemVerilog
module ext_clk_monitor(
    input ext_clk,      // External clock to monitor
    input ref_clk,      // Reference clock
    input rst_n,        // Reset
    output reg clk_out, // Output clock
    output reg timeout  // Timeout indicator
);
    // Two-stage synchronizer for crossing clock domains
    reg ext_clk_sync1, ext_clk_sync2;
    // Optimized 3-bit counter with explicit bit width
    reg [2:0] watchdog;
    // Edge detection signal
    reg edge_detected;
    
    // Combined always block for all logic with same clock and reset
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            ext_clk_sync1 <= 1'b0;
            ext_clk_sync2 <= 1'b0;
            edge_detected <= 1'b0;
            watchdog <= 3'd0;
            timeout <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // Clock domain synchronization
            ext_clk_sync1 <= ext_clk;
            ext_clk_sync2 <= ext_clk_sync1;
            
            // Edge detection
            edge_detected <= (ext_clk_sync2 != ext_clk_sync1);
            
            // Watchdog counter and output logic
            if (edge_detected) begin
                watchdog <= 3'd0;
                timeout <= 1'b0;
                clk_out <= ext_clk_sync2;
            end else begin
                // Prevent unnecessary increments once max is reached
                watchdog <= (watchdog == 3'd7) ? watchdog : watchdog + 1'b1;
                // Set timeout only when watchdog reaches maximum
                timeout <= (watchdog == 3'd6) ? 1'b1 : timeout;
            end
        end
    end
endmodule