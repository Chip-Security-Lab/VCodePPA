module decoder_dual_port (
    input [3:0] rd_addr, wr_addr,
    output [15:0] rd_sel, wr_sel
);
    assign rd_sel = 1'b1 << rd_addr;
    assign wr_sel = 1'b1 << wr_addr;
endmodule