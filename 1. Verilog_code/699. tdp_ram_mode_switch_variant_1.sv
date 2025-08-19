//SystemVerilog
module tdp_ram_mode_switch #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input mode,
    input [AW-1:0] port1_addr,
    input [DW-1:0] port1_din,
    output reg [DW-1:0] port1_dout,
    input port1_we,
    input port1_re,
    input [AW-1:0] port2_addr,
    input [DW-1:0] port2_din,
    output reg [DW-1:0] port2_dout,
    input port2_we,
    input port2_re
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] mem_buf1, mem_buf2;
reg [AW-1:0] addr1_buf, addr2_buf;
reg we1_buf, we2_buf, re1_buf, re2_buf;
reg mode_buf;

always @(posedge clk) begin
    // Buffer inputs
    addr1_buf <= port1_addr;
    addr2_buf <= port2_addr;
    we1_buf <= port1_we;
    we2_buf <= port2_we;
    re1_buf <= port1_re;
    re2_buf <= port2_re;
    mode_buf <= mode;

    // Port1 operation
    if (mode_buf) begin
        if (we1_buf) mem[addr1_buf] <= port1_din;
        if (re1_buf) mem_buf1 <= mem[addr1_buf];
    end else begin
        if (we1_buf) mem[addr1_buf] <= port1_din;
        mem_buf1 <= mem[addr1_buf];
    end
    port1_dout <= mem_buf1;

    // Port2 operation
    if (mode_buf) begin
        if (we2_buf) mem[addr2_buf] <= port2_din;
        if (re2_buf) mem_buf2 <= mem[addr2_buf];
    end else begin
        if (we2_buf) mem[addr2_buf] <= port2_din;
        mem_buf2 <= mem[addr2_buf];
    end
    port2_dout <= mem_buf2;
end

endmodule