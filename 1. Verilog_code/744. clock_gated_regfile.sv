module clock_gated_regfile #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input global_en,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
reg [DW-1:0] mem [0:(1<<AW)-1];
wire region_clk = clk & global_en & (addr[5:4] != 2'b11); // 关闭最后1/4区域

always @(posedge region_clk) begin
    if (wr_en) mem[addr] <= din;
end

assign dout = mem[addr];
endmodule