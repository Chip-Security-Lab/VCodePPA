//SystemVerilog
module multi_level_rst_sync (
    input  wire clock,
    input  wire hard_rst_n,
    input  wire soft_rst_n,
    output wire system_rst_n,
    output wire periph_rst_n
);
    // Pre-registered reset signals
    reg hard_rst_meta, hard_rst_sync;
    reg soft_rst_meta, soft_rst_sync;
    
    // Hard reset synchronizer with reduced logic depth
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            hard_rst_meta  <= 1'b0;
            hard_rst_sync  <= 1'b0;
        end
        else begin
            hard_rst_meta  <= 1'b1;
            hard_rst_sync  <= hard_rst_meta;
        end
    end
    
    // Soft reset synchronizer with balanced logic paths
    // Separate from hard reset logic to reduce critical path
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            soft_rst_meta  <= 1'b0;
            soft_rst_sync  <= 1'b0;
        end
        else begin
            // Pre-compute condition for soft reset
            // This eliminates cascaded conditional logic
            soft_rst_meta  <= soft_rst_n && hard_rst_sync;
            soft_rst_sync  <= soft_rst_meta;
        end
    end
    
    // Direct assignment to outputs
    assign system_rst_n = hard_rst_sync;
    assign periph_rst_n = soft_rst_sync;
endmodule