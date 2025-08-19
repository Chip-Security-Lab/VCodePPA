//SystemVerilog
//IEEE 1364-2005 Verilog standard
module clk_gated_rst_sync (
    input  wire clk,           // System clock
    input  wire clk_en,        // Clock enable signal
    input  wire async_rst_n,   // Asynchronous reset (active low)
    output wire sync_rst_n     // Synchronized reset output (active low)
);
    // Reset synchronization pipeline registers
    reg  rst_sync_stage0;      // First synchronization stage
    reg  rst_sync_stage1;      // Second synchronization stage (output)
    wire stage0_gated_enable;  // Enable signal for first stage
    wire stage1_gated_enable;  // Enable signal for second stage
    
    // Generate individual clock enable signals for better timing
    // This reduces clock network loading and improves power efficiency
    assign stage0_gated_enable = clk_en;
    assign stage1_gated_enable = clk_en;
    
    // First synchronization stage with dedicated clock enable
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_sync_stage0 <= 1'b0;
        end else if (stage0_gated_enable) begin
            rst_sync_stage0 <= 1'b1;
        end
    end
    
    // Second synchronization stage with dedicated clock enable
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_sync_stage1 <= 1'b0;
        end else if (stage1_gated_enable) begin
            rst_sync_stage1 <= rst_sync_stage0;
        end
    end
    
    // Connect the synchronized reset to output
    assign sync_rst_n = rst_sync_stage1;
    
endmodule