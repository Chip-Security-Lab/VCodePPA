module tdp_ram_mode_switch #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input mode, // 0: True Dual-Port, 1: Simple Dual-Port
    // Port interface
    input [AW-1:0] port1_addr,
    input [DW-1:0] port1_din,
    output reg [DW-1:0] port1_dout,
    input port1_we,
    input port1_re,
    // Second port
    input [AW-1:0] port2_addr,
    input [DW-1:0] port2_din,
    output reg [DW-1:0] port2_dout,
    input port2_we,
    input port2_re
);

reg [DW-1:0] mem [0:(1<<AW)-1];

always @(posedge clk) begin
    // Port1 operation
    if (mode) begin // Simple dual-port mode
        if (port1_we) mem[port1_addr] <= port1_din;
        if (port1_re) port1_dout <= mem[port1_addr];
    end else begin // True dual-port
        if (port1_we) mem[port1_addr] <= port1_din;
        port1_dout <= mem[port1_addr];
    end
end

always @(posedge clk) begin
    // Port2 operation
    if (mode) begin // Shared port
        if (port2_we) mem[port2_addr] <= port2_din;
        if (port2_re) port2_dout <= mem[port2_addr];
    end else begin
        if (port2_we) mem[port2_addr] <= port2_din;
        port2_dout <= mem[port2_addr];
    end
end
endmodule
