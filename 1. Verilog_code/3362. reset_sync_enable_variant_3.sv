//SystemVerilog
module reset_sync_enable (
    input  wire clk,      // System clock
    input  wire en,       // Enable signal
    input  wire rst_n,    // Asynchronous reset (active low)
    output reg  sync_reset // Synchronized reset output
);

    // Reset synchronization pipeline
    reg reset_sync_stage1;
    reg reset_sync_stage2;
    
    // First pipeline stage synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset path
            reset_sync_stage1 <= 1'b0;
        end else if (en) begin
            // Enable-gated first stage
            reset_sync_stage1 <= 1'b1;
        end
    end
    
    // Second pipeline stage synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset path
            reset_sync_stage2 <= 1'b0;
        end else if (en) begin
            // Enable-gated second stage
            reset_sync_stage2 <= reset_sync_stage1;
        end
    end
    
    // Output stage synchronization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset path
            sync_reset <= 1'b0;
        end else if (en) begin
            // Enable-gated output stage
            sync_reset <= reset_sync_stage2;
        end
    end

endmodule