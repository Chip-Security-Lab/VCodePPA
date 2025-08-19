//SystemVerilog
// 顶层模块
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

// 时钟门控逻辑
wire region_clk;
clock_gate_ctrl #(
    .AW(AW)
) u_clock_gate_ctrl (
    .clk(clk),
    .global_en(global_en),
    .addr(addr),
    .region_clk(region_clk)
);

// 寄存器文件存储单元
regfile_mem #(
    .DW(DW),
    .AW(AW)
) u_regfile_mem (
    .clk(region_clk),
    .wr_en(wr_en),
    .addr(addr),
    .din(din),
    .dout(dout)
);

endmodule

// 时钟门控控制模块
module clock_gate_ctrl #(
    parameter AW = 6
)(
    input clk,
    input global_en,
    input [AW-1:0] addr,
    output reg region_clk
);

always @(*) begin
    region_clk = clk & global_en & (addr[5:4] != 2'b11);
end

endmodule

// 寄存器文件存储模块
module regfile_mem #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] mem [0:(1<<AW)-1];

always @(posedge clk) begin
    if (wr_en) mem[addr] <= din;
end

assign dout = mem[addr];

endmodule