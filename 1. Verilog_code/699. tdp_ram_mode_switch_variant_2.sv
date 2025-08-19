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

// Stage 1: Address and Control Pipeline
reg [AW-1:0] port1_addr_stage1, port2_addr_stage1;
reg port1_we_stage1, port1_re_stage1, port2_we_stage1, port2_re_stage1;
reg mode_stage1;

always @(posedge clk) begin
    port1_addr_stage1 <= port1_addr;
    port2_addr_stage1 <= port2_addr;
    port1_we_stage1 <= port1_we;
    port1_re_stage1 <= port1_re;
    port2_we_stage1 <= port2_we;
    port2_re_stage1 <= port2_re;
    mode_stage1 <= mode;
end

// Stage 2: Memory Access Pipeline
reg [DW-1:0] port1_din_stage2, port2_din_stage2;
reg [AW-1:0] port1_addr_stage2, port2_addr_stage2;
reg port1_we_stage2, port1_re_stage2, port2_we_stage2, port2_re_stage2;
reg mode_stage2;

always @(posedge clk) begin
    port1_din_stage2 <= port1_din;
    port2_din_stage2 <= port2_din;
    port1_addr_stage2 <= port1_addr_stage1;
    port2_addr_stage2 <= port2_addr_stage1;
    port1_we_stage2 <= port1_we_stage1;
    port1_re_stage2 <= port1_re_stage1;
    port2_we_stage2 <= port2_we_stage1;
    port2_re_stage2 <= port2_re_stage1;
    mode_stage2 <= mode_stage1;
end

// Stage 3: Memory Write and Read for Port 1
always @(posedge clk) begin
    if (mode_stage2) begin
        if (port1_we_stage2) mem[port1_addr_stage2] <= port1_din_stage2;
        if (port1_re_stage2) port1_dout <= mem[port1_addr_stage2];
    end else begin
        if (port1_we_stage2) mem[port1_addr_stage2] <= port1_din_stage2;
        port1_dout <= mem[port1_addr_stage2];
    end
end

// Stage 3: Memory Write and Read for Port 2
always @(posedge clk) begin
    if (mode_stage2) begin
        if (port2_we_stage2) mem[port2_addr_stage2] <= port2_din_stage2;
        if (port2_re_stage2) port2_dout <= mem[port2_addr_stage2];
    end else begin
        if (port2_we_stage2) mem[port2_addr_stage2] <= port2_din_stage2;
        port2_dout <= mem[port2_addr_stage2];
    end
end

endmodule