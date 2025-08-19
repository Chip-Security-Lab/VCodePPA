//SystemVerilog
module tdp_ram_mode_switch #(
    parameter DW = 32,
    parameter AW = 8
)(
    input clk,
    input rst_n,
    input mode,
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

// Pipeline stage 1: Address and control signal registration
reg [AW-1:0] port1_addr_stage1;
reg [AW-1:0] port2_addr_stage1;
reg port1_we_stage1;
reg port1_re_stage1;
reg port2_we_stage1;
reg port2_re_stage1;
reg mode_stage1;

// Pipeline stage 2: Memory access
reg [DW-1:0] port1_dout_stage2;
reg [DW-1:0] port2_dout_stage2;
reg [AW-1:0] port1_addr_stage2;
reg [AW-1:0] port2_addr_stage2;
reg port1_re_stage2;
reg port2_re_stage2;
reg mode_stage2;

// Pipeline stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        port1_addr_stage1 <= 0;
        port2_addr_stage1 <= 0;
        port1_we_stage1 <= 0;
        port1_re_stage1 <= 0;
        port2_we_stage1 <= 0;
        port2_re_stage1 <= 0;
        mode_stage1 <= 0;
    end else begin
        port1_addr_stage1 <= port1_addr;
        port2_addr_stage1 <= port2_addr;
        port1_we_stage1 <= port1_we;
        port1_re_stage1 <= port1_re;
        port2_we_stage1 <= port2_we;
        port2_re_stage1 <= port2_re;
        mode_stage1 <= mode;
    end
end

// Pipeline stage 2: Memory operations
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        port1_dout_stage2 <= 0;
        port2_dout_stage2 <= 0;
        port1_addr_stage2 <= 0;
        port2_addr_stage2 <= 0;
        port1_re_stage2 <= 0;
        port2_re_stage2 <= 0;
        mode_stage2 <= 0;
    end else begin
        // Port1 write operation - flattened if-else
        if (port1_we_stage1) 
            mem[port1_addr_stage1] <= port1_din;

        // Port2 write operation - flattened if-else
        if (port2_we_stage1) 
            mem[port2_addr_stage1] <= port2_din;

        // Register read addresses and control signals
        port1_addr_stage2 <= port1_addr_stage1;
        port2_addr_stage2 <= port2_addr_stage1;
        port1_re_stage2 <= port1_re_stage1;
        port2_re_stage2 <= port2_re_stage1;
        mode_stage2 <= mode_stage1;
    end
end

// Pipeline stage 3: Output registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        port1_dout <= 0;
        port2_dout <= 0;
    end else begin
        // Port1 read operation - flattened if-else
        if (mode_stage2 && port1_re_stage2)
            port1_dout <= mem[port1_addr_stage2];
        else if (!mode_stage2)
            port1_dout <= mem[port1_addr_stage2];

        // Port2 read operation - flattened if-else
        if (mode_stage2 && port2_re_stage2)
            port2_dout <= mem[port2_addr_stage2];
        else if (!mode_stage2)
            port2_dout <= mem[port2_addr_stage2];
    end
end

endmodule