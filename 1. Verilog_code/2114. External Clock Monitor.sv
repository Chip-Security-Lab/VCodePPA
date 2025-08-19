module ext_clk_monitor(
    input ext_clk,      // External clock to monitor
    input ref_clk,      // Reference clock
    input rst_n,        // Reset
    output reg clk_out, // Output clock
    output reg timeout  // Timeout indicator
);
    reg ext_clk_sync1, ext_clk_sync2;
    reg [2:0] watchdog;
    
    // Synchronize external clock to reference domain
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_clk_sync1 <= 1'b0;
            ext_clk_sync2 <= 1'b0;
            watchdog <= 3'd0;
            timeout <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            ext_clk_sync1 <= ext_clk;
            ext_clk_sync2 <= ext_clk_sync1;
            
            if (ext_clk_sync2 != ext_clk_sync1) begin
                watchdog <= 3'd0;
                timeout <= 1'b0;
                clk_out <= ext_clk_sync2;
            end else if (watchdog < 3'd7) begin
                watchdog <= watchdog + 1'b1;
            end else begin
                timeout <= 1'b1;
            end
        end
    end
endmodule