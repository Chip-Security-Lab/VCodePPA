module asymmetric_regfile #(
    parameter WR_DW = 64,
    parameter RD_DW = 32
)(
    input clk,
    input wr_en,
    input [2:0] wr_addr,
    input [WR_DW-1:0] din,
    input [3:0] rd_addr, // 地址多1位用于选择高低半部
    output [RD_DW-1:0] dout
);
reg [WR_DW-1:0] mem [0:7];
wire sel_high = rd_addr[3];

always @(posedge clk) begin
    if (wr_en) mem[wr_addr] <= din;
end

assign dout = sel_high ? 
    mem[rd_addr[2:0]][WR_DW-1:RD_DW] : 
    mem[rd_addr[2:0]][RD_DW-1:0];
endmodule