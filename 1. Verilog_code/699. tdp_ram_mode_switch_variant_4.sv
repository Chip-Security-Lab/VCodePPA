//SystemVerilog
// Memory core module
module tdp_ram_core #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    input we,
    input re,
    input en
);

reg [DW-1:0] mem [0:(1<<AW)-1];

always @(posedge clk) begin
    if (en) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
end

endmodule

// Port control module
module tdp_ram_port_ctrl #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input mode,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    input we,
    input re,
    output reg port_en
);

always @(posedge clk) begin
    port_en <= mode ? (we | re) : 1'b1;
end

endmodule

// Top level module
module tdp_ram_mode_switch #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input mode,
    input [AW-1:0] port1_addr,
    input [DW-1:0] port1_din,
    output [DW-1:0] port1_dout,
    input port1_we,
    input port1_re,
    input [AW-1:0] port2_addr,
    input [DW-1:0] port2_din,
    output [DW-1:0] port2_dout,
    input port2_we,
    input port2_re
);

wire port1_en, port2_en;

// Port 1 control
tdp_ram_port_ctrl #(
    .DW(DW),
    .AW(AW)
) port1_ctrl (
    .clk(clk),
    .mode(mode),
    .addr(port1_addr),
    .din(port1_din),
    .dout(port1_dout),
    .we(port1_we),
    .re(port1_re),
    .port_en(port1_en)
);

// Port 2 control
tdp_ram_port_ctrl #(
    .DW(DW),
    .AW(AW)
) port2_ctrl (
    .clk(clk),
    .mode(mode),
    .addr(port2_addr),
    .din(port2_din),
    .dout(port2_dout),
    .we(port2_we),
    .re(port2_re),
    .port_en(port2_en)
);

// Memory core for port 1
tdp_ram_core #(
    .DW(DW),
    .AW(AW)
) mem1 (
    .clk(clk),
    .addr(port1_addr),
    .din(port1_din),
    .dout(port1_dout),
    .we(port1_we),
    .re(port1_re),
    .en(port1_en)
);

// Memory core for port 2
tdp_ram_core #(
    .DW(DW),
    .AW(AW)
) mem2 (
    .clk(clk),
    .addr(port2_addr),
    .din(port2_din),
    .dout(port2_dout),
    .we(port2_we),
    .re(port2_re),
    .en(port2_en)
);

endmodule