//SystemVerilog
module DualEdgeLatch #(parameter DW=16) (
    input clk,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    reg [DW-1:0] pos_edge_reg;
    reg [DW-1:0] neg_edge_reg;
    
    always @(posedge clk or negedge clk) begin
        if (clk)
            pos_edge_reg <= din;
        else
            neg_edge_reg <= din;
    end
    
    always @(*) begin
        dout = clk ? pos_edge_reg : neg_edge_reg;
    end
endmodule