//SystemVerilog
module crossbar_multiclk #(DW=8) (
    input clk_a, clk_b,
    input [1:0][DW-1:0] din_a,
    output reg [1:0][DW-1:0] dout_b
);
    // Two-stage synchronizer for clock domain crossing
    reg [1:0][DW-1:0] sync_stage1;
    reg [1:0][DW-1:0] sync_stage2;
    
    // Optimized subtractor implementation
    wire [1:0] difference;
    
    // Simplified 2-bit subtractor using direct comparison
    // This eliminates the cascaded borrow chain for better timing
    assign difference = din_a[0][1:0] - din_a[1][1:0];
    
    // First stage (clk_a domain)
    always @(posedge clk_a) begin
        // Use non-blocking assignments for all registers
        sync_stage1[0][DW-1:2] <= din_a[0][DW-1:2];
        sync_stage1[0][1:0] <= difference;
        sync_stage1[1] <= din_a[1];
    end
    
    // Second stage (clk_b domain)
    always @(posedge clk_b) begin
        sync_stage2 <= sync_stage1;
        dout_b <= sync_stage2;
    end
endmodule