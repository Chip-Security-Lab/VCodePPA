//SystemVerilog
// SystemVerilog
//------------------------------------------------------------------------------
// Module: clk_gated_rst_sync
// Description: Reset synchronizer with clock gating and increased pipeline depth
// Standard: IEEE 1364-2005 Verilog
//------------------------------------------------------------------------------
module clk_gated_rst_sync (
    input  wire clk,         // Input clock
    input  wire clk_en,      // Clock enable signal
    input  wire async_rst_n, // Asynchronous reset (active low)
    output wire sync_rst_n   // Synchronized reset output (active low)
);
    // Internal signals
    reg  [3:0] sync_stages;  // Four-stage synchronizer registers
    wire       gated_clk;    // Gated clock signal
    
    // Optimized clock gating logic with registered enable
    reg clk_en_stage1;
    
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            clk_en_stage1 <= 1'b0;
        end
        else begin
            clk_en_stage1 <= clk_en;
        end
    end
    
    // Clock gating with registered enable for better timing
    assign gated_clk = clk & clk_en_stage1;
    
    // Reset synchronization logic - First stage
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Asynchronous reset path - clear first stage
            sync_stages[0] <= 1'b0;
        end
        else begin
            // Normal operation - shift in '1' to first stage
            sync_stages[0] <= 1'b1;
        end
    end
    
    // Second stage synchronizer
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Asynchronous reset path - clear second stage
            sync_stages[1] <= 1'b0;
        end
        else begin
            // Normal operation - propagate first stage to second
            sync_stages[1] <= sync_stages[0];
        end
    end
    
    // Third stage synchronizer - Added for increased pipeline depth
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Asynchronous reset path - clear third stage
            sync_stages[2] <= 1'b0;
        end
        else begin
            // Normal operation - propagate second stage to third
            sync_stages[2] <= sync_stages[1];
        end
    end
    
    // Fourth stage synchronizer - Added for increased pipeline depth
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Asynchronous reset path - clear fourth stage
            sync_stages[3] <= 1'b0;
        end
        else begin
            // Normal operation - propagate third stage to fourth
            sync_stages[3] <= sync_stages[2];
        end
    end
    
    // Output assignment
    assign sync_rst_n = sync_stages[3];
    
endmodule