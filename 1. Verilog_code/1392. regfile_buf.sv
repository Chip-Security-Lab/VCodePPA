module regfile_buf #(parameter DW=32) (
    input clk,
    input [1:0] wr_sel, rd_sel,
    input wr_en,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] regs[0:3];
    always @(posedge clk) if(wr_en) regs[wr_sel] <= din;
    assign dout = regs[rd_sel];
endmodule
