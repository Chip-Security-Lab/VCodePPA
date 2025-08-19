//SystemVerilog
module crossbar_multiclk #(DW=8) (
    input clk_a, clk_b,
    input [1:0][DW-1:0] din_a,
    output [1:0][DW-1:0] dout_b
);
    // First stage synchronizer (clk_a domain)
    reg [1:0][DW-1:0] sync_stage1;
    
    // Second stage and output registers (clk_b domain)
    reg [1:0][DW-1:0] sync_stage2;
    reg [1:0][DW-1:0] dout_b_reg;
    
    // First stage (clk_a domain)
    always @(posedge clk_a) begin
        sync_stage1 <= din_a;
    end
    
    // Second stage (clk_b domain)
    always @(posedge clk_b) begin
        sync_stage2 <= sync_stage1;
    end
    
    // Output assignment without additional register
    assign dout_b = sync_stage2;
endmodule