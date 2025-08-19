module cdc_buffer #(parameter DW=8) (
    input src_clk, dst_clk,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] src_reg, meta_reg, dst_reg;
    
    always @(posedge src_clk) src_reg <= din;
    always @(posedge dst_clk) begin
        meta_reg <= src_reg;
        dst_reg <= meta_reg;
    end
    assign dout = dst_reg;
endmodule
