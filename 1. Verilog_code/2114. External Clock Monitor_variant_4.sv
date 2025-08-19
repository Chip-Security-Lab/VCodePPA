//SystemVerilog
module ext_clk_monitor(
    input ext_clk,      // External clock to monitor
    input ref_clk,      // Reference clock
    input rst_n,        // Reset
    output reg clk_out, // Output clock
    output reg timeout  // Timeout indicator
);
    // Stage 1: Input synchronization and edge detection
    reg ext_clk_stage1;
    reg ext_clk_stage2;
    reg edge_detected_stage1;
    reg valid_stage1;
    
    // Stage 2: Watchdog timer control
    reg [2:0] watchdog_stage2;
    reg timeout_stage2;
    reg edge_detected_stage2;
    reg valid_stage2;
    
    // Stage 3: Output generation
    reg clk_value_stage3;
    
    // Stage 1: Input sampling and edge detection
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_clk_stage1 <= 1'b0;
            ext_clk_stage2 <= 1'b0;
            edge_detected_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            ext_clk_stage1 <= ext_clk;
            ext_clk_stage2 <= ext_clk_stage1;
            edge_detected_stage1 <= (ext_clk_stage1 != ext_clk_stage2);
            valid_stage1 <= 1'b1;  // Always valid after reset
        end
    end
    
    // Stage 2: Watchdog timer logic
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            watchdog_stage2 <= 3'd0;
            timeout_stage2 <= 1'b0;
            edge_detected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            edge_detected_stage2 <= edge_detected_stage1;
            valid_stage2 <= valid_stage1;
            
            if (edge_detected_stage1) begin
                watchdog_stage2 <= 3'd0;
                timeout_stage2 <= 1'b0;
            end else if (watchdog_stage2 < 3'd7) begin
                watchdog_stage2 <= watchdog_stage2 + 1'b1;
                timeout_stage2 <= 1'b0;
            end else begin
                timeout_stage2 <= 1'b1;
            end
        end
    end
    
    // Stage 3: Output generation
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
            timeout <= 1'b0;
            clk_value_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            timeout <= timeout_stage2;
            
            if (edge_detected_stage2) begin
                clk_value_stage3 <= ext_clk_stage2;
                clk_out <= clk_value_stage3;
            end
        end
    end
endmodule