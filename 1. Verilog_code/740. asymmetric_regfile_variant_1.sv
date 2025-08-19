//SystemVerilog
module asymmetric_regfile #(
    parameter WR_DW = 64,
    parameter RD_DW = 32
)(
    input clk,
    input wr_en,
    input [2:0] wr_addr,
    input [WR_DW-1:0] din,
    input [3:0] rd_addr,
    output [RD_DW-1:0] dout
);

reg [WR_DW-1:0] mem [0:7];
wire sel_high = rd_addr[3];
wire [2:0] rd_addr_low = rd_addr[2:0];

// 使用二进制补码减法算法实现
wire [RD_DW-1:0] data_low = mem[rd_addr_low][RD_DW-1:0];
wire [RD_DW-1:0] data_high = mem[rd_addr_low][WR_DW-1:RD_DW];
wire [RD_DW-1:0] data_high_complement = ~data_high + 1'b1; // 计算二进制补码
wire [RD_DW-1:0] data_sel = sel_high ? data_high_complement : data_low;
wire [RD_DW-1:0] data_final = sel_high ? data_sel : data_sel; // 保持功能行为不变

always @(posedge clk) begin
    if (wr_en) mem[wr_addr] <= din;
end

assign dout = data_final;

endmodule