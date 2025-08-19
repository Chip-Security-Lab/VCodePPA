//SystemVerilog
module dual_clk_reset_dist(
    input wire clk_a, clk_b,
    input wire master_rst,
    output reg rst_domain_a, rst_domain_b
);
    // Domain A reset synchronization pipeline registers
    reg rst_sync_a_stage1;
    reg rst_sync_a_stage2;
    
    // Domain B reset synchronization pipeline registers
    reg rst_sync_b_stage1;
    reg rst_sync_b_stage2;
    
    // Domain A reset synchronization pipeline
    always @(posedge clk_a or posedge master_rst) begin
        if (master_rst) begin
            rst_sync_a_stage1 <= 1'b1;
            rst_sync_a_stage2 <= 1'b1;
            rst_domain_a <= 1'b1;
        end else begin
            rst_sync_a_stage1 <= 1'b0;
            rst_sync_a_stage2 <= rst_sync_a_stage1;
            rst_domain_a <= rst_sync_a_stage2;
        end
    end
    
    // Domain B reset synchronization pipeline
    always @(posedge clk_b or posedge master_rst) begin
        if (master_rst) begin
            rst_sync_b_stage1 <= 1'b1;
            rst_sync_b_stage2 <= 1'b1;
            rst_domain_b <= 1'b1;
        end else begin
            rst_sync_b_stage1 <= 1'b0;
            rst_sync_b_stage2 <= rst_sync_b_stage1;
            rst_domain_b <= rst_sync_b_stage2;
        end
    end
endmodule