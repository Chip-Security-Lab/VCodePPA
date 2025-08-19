//SystemVerilog
module multi_level_rst_sync (
    input  wire clock,
    input  wire hard_rst_n,
    input  wire soft_rst_n,
    output wire system_rst_n,
    output wire periph_rst_n
);
    // Internal registers for reset synchronization
    reg hard_rst_meta;
    reg soft_rst_meta;
    
    // Pre-synchronized signals (moved closer to inputs)
    reg hard_rst_pre_sync;
    reg soft_rst_pre_sync;
    
    // Hardware reset synchronizer - first stage
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            hard_rst_meta <= 1'b0;
        end else begin
            hard_rst_meta <= 1'b1;
        end
    end
    
    // Hardware reset synchronizer - second stage (moved before output)
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            hard_rst_pre_sync <= 1'b0;
        end else begin
            hard_rst_pre_sync <= hard_rst_meta;
        end
    end
    
    // Software reset synchronizer - first stage
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            soft_rst_meta <= 1'b0;
        end else if (!soft_rst_n) begin
            soft_rst_meta <= 1'b0;
        end else begin
            soft_rst_meta <= 1'b1;
        end
    end
    
    // Software reset synchronizer - second stage (moved before output)
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n) begin
            soft_rst_pre_sync <= 1'b0;
        end else if (!soft_rst_n) begin
            soft_rst_pre_sync <= 1'b0;
        end else begin
            soft_rst_pre_sync <= soft_rst_meta;
        end
    end
    
    // Output assignment through registered outputs
    assign system_rst_n = hard_rst_pre_sync;
    assign periph_rst_n = soft_rst_pre_sync;
endmodule