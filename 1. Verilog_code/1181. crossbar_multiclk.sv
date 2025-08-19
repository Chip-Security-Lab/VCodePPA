module crossbar_multiclk #(DW=8) (
    input clk_a, clk_b,
    input [1:0][DW-1:0] din_a,
    output reg [1:0][DW-1:0] dout_b
);
    // Two-stage synchronizer for clock domain crossing
    reg [1:0][DW-1:0] sync_stage1;
    reg [1:0][DW-1:0] sync_stage2;
    
    // First stage (clk_a domain)
    always @(posedge clk_a) begin
        sync_stage1 <= din_a;
    end
    
    // Second stage (clk_b domain)
    always @(posedge clk_b) begin
        sync_stage2 <= sync_stage1;
        dout_b <= sync_stage2;
    end
endmodule