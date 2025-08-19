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

reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
wire clk_gated = sys_clk & pwr_en;

// Stage 1: Address and control signal pipeline
reg [ADDR_WIDTH-1:0] x_addr_stage1, y_addr_stage1;
reg [DATA_WIDTH-1:0] x_din_stage1, y_din_stage1;
reg x_we_stage1, x_ce_stage1, y_we_stage1, y_ce_stage1;

// Stage 2: Memory access pipeline
reg [ADDR_WIDTH-1:0] x_addr_stage2, y_addr_stage2;
reg [DATA_WIDTH-1:0] x_din_stage2, y_din_stage2;
reg x_we_stage2, x_ce_stage2, y_we_stage2, y_ce_stage2;
reg [DATA_WIDTH-1:0] x_dout_stage2, y_dout_stage2;

// Stage 3: Output pipeline
reg [DATA_WIDTH-1:0] x_dout_stage3, y_dout_stage3;

// Stage 4: Final output pipeline
reg [DATA_WIDTH-1:0] x_dout_stage4, y_dout_stage4;

always @(posedge clk_gated) begin
    // Stage 1: Register inputs
    x_addr_stage1 <= x_addr;
    y_addr_stage1 <= y_addr;
    x_din_stage1 <= x_din;
    y_din_stage1 <= y_din;
    x_we_stage1 <= x_we;
    x_ce_stage1 <= x_ce;
    y_we_stage1 <= y_we;
    y_ce_stage1 <= y_ce;

    // Stage 2: Memory access
    x_addr_stage2 <= x_addr_stage1;
    y_addr_stage2 <= y_addr_stage1;
    x_din_stage2 <= x_din_stage1;
    y_din_stage2 <= y_din_stage1;
    x_we_stage2 <= x_we_stage1;
    x_ce_stage2 <= x_ce_stage1;
    y_we_stage2 <= y_we_stage1;
    y_ce_stage2 <= y_ce_stage1;

    if (x_ce_stage1) begin
        if (x_we_stage1) mem[x_addr_stage1] <= x_din_stage1;
        x_dout_stage2 <= mem[x_addr_stage1];
    end
    if (y_ce_stage1) begin
        if (y_we_stage1) mem[y_addr_stage1] <= y_din_stage1;
        y_dout_stage2 <= mem[y_addr_stage1];
    end

    // Stage 3: Output register
    x_dout_stage3 <= x_dout_stage2;
    y_dout_stage3 <= y_dout_stage2;

    // Stage 4: Final output register
    x_dout_stage4 <= x_dout_stage3;
    y_dout_stage4 <= y_dout_stage3;
end

assign x_dout = x_dout_stage4;
assign y_dout = y_dout_stage4;

endmodule