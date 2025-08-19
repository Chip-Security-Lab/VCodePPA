//SystemVerilog
module sram_nv_backup #(
    parameter DW = 8,
    parameter AW = 10
)(
    input clk,
    input power_good,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] volatile_mem [0:(1<<AW)-1];
reg [DW-1:0] nv_mem [0:(1<<AW)-1];
reg [DW-1:0] volatile_mem_buf [0:(1<<AW)-1];
reg [DW-1:0] dout_reg;
reg [AW-1:0] addr_reg;
reg we_reg;
reg power_good_reg;
reg [DW-1:0] din_reg;

// Pipeline control signals
always @(posedge clk) begin
    addr_reg <= addr;
    we_reg <= we;
    power_good_reg <= power_good;
    din_reg <= din;
end

// Memory operations with balanced paths
always @(posedge clk) begin
    if (!power_good_reg) begin
        volatile_mem[addr_reg] <= nv_mem[addr_reg];
        volatile_mem_buf[addr_reg] <= nv_mem[addr_reg];
    end else if (we_reg) begin
        volatile_mem[addr_reg] <= din_reg;
        volatile_mem_buf[addr_reg] <= din_reg;
        nv_mem[addr_reg] <= din_reg;
    end
end

// Output pipeline
always @(posedge clk) begin
    dout_reg <= volatile_mem_buf[addr_reg];
end

assign dout = dout_reg;

endmodule