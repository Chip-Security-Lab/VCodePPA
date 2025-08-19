//SystemVerilog
module tdp_ram_dual_clock #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 8
)(
    // Port A domain
    input clk_a,
    input [A_WIDTH-1:0] adr_a,
    input [D_WIDTH-1:0] dat_a_in,
    output reg [D_WIDTH-1:0] dat_a_out,
    input wr_a,
    input rd_a,
    
    // Port B domain
    input clk_b,
    input [A_WIDTH-1:0] adr_b,
    input [D_WIDTH-1:0] dat_b_in,
    output reg [D_WIDTH-1:0] dat_b_out,
    input wr_b,
    input rd_b
);

(* ram_style = "block" *) reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

// Pipeline registers for Port A
reg [A_WIDTH-1:0] adr_a_stage1;
reg [D_WIDTH-1:0] dat_a_in_stage1;
reg wr_a_stage1;
reg rd_a_stage1;

// Pipeline registers for Port B
reg [A_WIDTH-1:0] adr_b_stage1;
reg [D_WIDTH-1:0] dat_b_in_stage1;
reg wr_b_stage1;
reg rd_b_stage1;

// Stage 1: Input register
always @(posedge clk_a) begin
    adr_a_stage1 <= adr_a;
    dat_a_in_stage1 <= dat_a_in;
    wr_a_stage1 <= wr_a;
    rd_a_stage1 <= rd_a;
end

always @(posedge clk_b) begin
    adr_b_stage1 <= adr_b;
    dat_b_in_stage1 <= dat_b_in;
    wr_b_stage1 <= wr_b;
    rd_b_stage1 <= rd_b;
end

// Stage 2: Memory access
always @(posedge clk_a) begin
    if (wr_a_stage1) mem[adr_a_stage1] <= dat_a_in_stage1;
    if (rd_a_stage1) dat_a_out <= mem[adr_a_stage1];
end

always @(posedge clk_b) begin
    if (wr_b_stage1) mem[adr_b_stage1] <= dat_b_in_stage1;
    if (rd_b_stage1) dat_b_out <= mem[adr_b_stage1];
end

endmodule