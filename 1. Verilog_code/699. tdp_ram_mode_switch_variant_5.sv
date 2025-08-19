//SystemVerilog
// Top-level module
module tdp_ram_mode_switch #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input mode,
    // Port1 interface
    input [AW-1:0] port1_addr,
    input [DW-1:0] port1_din,
    output reg [DW-1:0] port1_dout,
    input port1_we,
    input port1_re,
    // Port2 interface
    input [AW-1:0] port2_addr,
    input [DW-1:0] port2_din,
    output reg [DW-1:0] port2_dout,
    input port2_we,
    input port2_re
);

    // Memory core signals
    wire [AW-1:0] mem1_addr, mem2_addr;
    wire [DW-1:0] mem1_din, mem2_din;
    wire [DW-1:0] mem1_dout, mem2_dout;
    wire mem1_we, mem2_we;
    wire mem1_re, mem2_re;

    // Instantiate memory cores
    memory_core #(DW, AW) mem1 (
        .clk(clk),
        .addr(mem1_addr),
        .din(mem1_din),
        .dout(mem1_dout),
        .we(mem1_we),
        .re(mem1_re)
    );

    memory_core #(DW, AW) mem2 (
        .clk(clk),
        .addr(mem2_addr),
        .din(mem2_din),
        .dout(mem2_dout),
        .we(mem2_we),
        .re(mem2_re)
    );

    // Instantiate port controllers
    port_controller #(DW, AW) port1_ctrl (
        .clk(clk),
        .mode(mode),
        .addr(port1_addr),
        .din(port1_din),
        .dout(port1_dout),
        .we(port1_we),
        .re(port1_re),
        .mem_addr(mem1_addr),
        .mem_din(mem1_din),
        .mem_dout(mem1_dout),
        .mem_we(mem1_we),
        .mem_re(mem1_re)
    );

    port_controller #(DW, AW) port2_ctrl (
        .clk(clk),
        .mode(mode),
        .addr(port2_addr),
        .din(port2_din),
        .dout(port2_dout),
        .we(port2_we),
        .re(port2_re),
        .mem_addr(mem2_addr),
        .mem_din(mem2_din),
        .mem_dout(mem2_dout),
        .mem_we(mem2_we),
        .mem_re(mem2_re)
    );

endmodule

// Memory core module
module memory_core #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    input we,
    input re
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    always @(posedge clk) begin
        mem[addr] <= we ? din : mem[addr];
        dout <= re ? mem[addr] : dout;
    end
endmodule

// Port controller module
module port_controller #(
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
    // Memory interface
    output reg [AW-1:0] mem_addr,
    output reg [DW-1:0] mem_din,
    input [DW-1:0] mem_dout,
    output reg mem_we,
    output reg mem_re
);
    always @(posedge clk) begin
        mem_addr <= addr;
        mem_din <= din;
        mem_we <= we;
        mem_re <= mode ? re : 1'b1;
        dout <= mem_dout;
    end
endmodule