//SystemVerilog
module ext_clk_monitor(
    input ext_clk,      // External clock to monitor
    input ref_clk,      // Reference clock
    input rst_n,        // Reset
    output reg clk_out, // Output clock
    output reg timeout  // Timeout indicator
);
    reg ext_clk_sync1, ext_clk_sync2;
    reg [2:0] watchdog;
    reg edge_detected;
    
    // Buffered signals for ext_clk_sync2 (high fanout)
    reg ext_clk_sync2_buf1;
    reg ext_clk_sync2_buf2;
    
    // Carry generation and propagation signals for skip-carry adder
    wire [2:0] g, p;    // Generate and propagate
    wire [2:0] c;       // Carries
    wire group_p;       // Group propagate signal
    
    // Generate and propagate signals for skip-carry adder
    assign g[0] = watchdog[0] & 1'b1;  // Generate for bit 0
    assign g[1] = watchdog[1] & 1'b0;  // Generate for bit 1
    assign g[2] = watchdog[2] & 1'b0;  // Generate for bit 2
    
    assign p[0] = watchdog[0] | 1'b1;  // Propagate for bit 0
    assign p[1] = watchdog[1] | 1'b0;  // Propagate for bit 1
    assign p[2] = watchdog[2] | 1'b0;  // Propagate for bit 2
    
    // Group propagate signal
    assign group_p = &p[1:0];  // p[0] AND p[1]
    
    // Carry computation using skip-carry method
    assign c[0] = 1'b0;  // Initial carry is 0
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & (group_p ? c[0] : c[1]));
    
    // Skip-carry adder sum computation
    wire [2:0] watchdog_next;
    assign watchdog_next[0] = watchdog[0] ^ 1'b1 ^ c[0];
    assign watchdog_next[1] = watchdog[1] ^ 1'b0 ^ c[1];
    assign watchdog_next[2] = watchdog[2] ^ 1'b0 ^ c[2];
    
    // Synchronize external clock to reference domain
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_clk_sync1 <= 1'b0;
            ext_clk_sync2 <= 1'b0;
            ext_clk_sync2_buf1 <= 1'b0;
            ext_clk_sync2_buf2 <= 1'b0;
            edge_detected <= 1'b0;
            watchdog <= 3'd0;
            timeout <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            ext_clk_sync1 <= ext_clk;
            ext_clk_sync2 <= ext_clk_sync1;
            
            // Buffer registers for high fanout signal
            ext_clk_sync2_buf1 <= ext_clk_sync2;
            ext_clk_sync2_buf2 <= ext_clk_sync2;
            
            // Edge detection using first buffer
            edge_detected <= (ext_clk_sync2_buf1 != ext_clk_sync1);
            
            if (edge_detected) begin
                watchdog <= 3'd0;
                timeout <= 1'b0;
                clk_out <= ext_clk_sync2_buf2; // Use second buffer for clk_out
            end else if (watchdog < 3'd7) begin
                // Use skip-carry adder implementation
                watchdog <= watchdog_next;
            end else begin
                timeout <= 1'b1;
            end
        end
    end
endmodule