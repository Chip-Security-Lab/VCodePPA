//SystemVerilog
module tdp_ram_clock_gating #(
    parameter DATA_WIDTH = 18,
    parameter ADDR_WIDTH = 9
)(
    input sys_clk, 
    input pwr_en,
    // Port X
    input [ADDR_WIDTH-1:0] x_addr,
    input [DATA_WIDTH-1:0] x_din,
    output reg [DATA_WIDTH-1:0] x_dout,
    input x_we, x_ce,
    // Port Y
    input [ADDR_WIDTH-1:0] y_addr,
    input [DATA_WIDTH-1:0] y_din,
    output reg [DATA_WIDTH-1:0] y_dout,
    input y_we, y_ce
);

wire clk_gated = sys_clk & pwr_en;

// Memory array module with pipeline stages
memory_array_pipelined #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) mem_array (
    .clk(clk_gated),
    // Port X
    .x_addr(x_addr),
    .x_din(x_din),
    .x_dout(x_dout),
    .x_we(x_we),
    .x_ce(x_ce),
    // Port Y
    .y_addr(y_addr),
    .y_din(y_din),
    .y_dout(y_dout),
    .y_we(y_we),
    .y_ce(y_ce)
);

endmodule

module memory_array_pipelined #(
    parameter DATA_WIDTH = 18,
    parameter ADDR_WIDTH = 9
)(
    input clk,
    // Port X
    input [ADDR_WIDTH-1:0] x_addr,
    input [DATA_WIDTH-1:0] x_din,
    output reg [DATA_WIDTH-1:0] x_dout,
    input x_we, x_ce,
    // Port Y
    input [ADDR_WIDTH-1:0] y_addr,
    input [DATA_WIDTH-1:0] y_din,
    output reg [DATA_WIDTH-1:0] y_dout,
    input y_we, y_ce
);

// Memory array
reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

// Pipeline registers
reg [ADDR_WIDTH-1:0] x_addr_reg, y_addr_reg;
reg [DATA_WIDTH-1:0] x_din_reg, y_din_reg;
reg x_we_reg, y_we_reg;
reg x_ce_reg, y_ce_reg;

// Stage 1: Input register
always @(posedge clk) begin
    x_addr_reg <= x_addr;
    y_addr_reg <= y_addr;
    x_din_reg <= x_din;
    y_din_reg <= y_din;
    x_we_reg <= x_we;
    y_we_reg <= y_we;
    x_ce_reg <= x_ce;
    y_ce_reg <= y_ce;
end

// Stage 2: Memory access and output register
always @(posedge clk) begin
    if (x_ce_reg) begin
        if (x_we_reg) mem[x_addr_reg] <= x_din_reg;
        x_dout <= mem[x_addr_reg];
    end
    if (y_ce_reg) begin
        if (y_we_reg) mem[y_addr_reg] <= y_din_reg;
        y_dout <= mem[y_addr_reg];
    end
end

endmodule