//SystemVerilog
module tdp_ram_dual_clock #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 8
)(
    input clk_a,
    input [A_WIDTH-1:0] adr_a,
    input [D_WIDTH-1:0] dat_a_in,
    output reg [D_WIDTH-1:0] dat_a_out,
    input wr_a,
    input rd_a,
    
    input clk_b,
    input [A_WIDTH-1:0] adr_b,
    input [D_WIDTH-1:0] dat_b_in,
    output reg [D_WIDTH-1:0] dat_b_out,
    input wr_b,
    input rd_b
);

(* ram_style = "block" *) reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

// Pipeline registers for Port A
reg [A_WIDTH-1:0] adr_a_pipe;
reg [D_WIDTH-1:0] dat_a_in_pipe;
reg wr_a_pipe, rd_a_pipe;

// Pipeline registers for Port B
reg [A_WIDTH-1:0] adr_b_pipe;
reg [D_WIDTH-1:0] dat_b_in_pipe;
reg wr_b_pipe, rd_b_pipe;

// Port A pipeline stage 1
always @(posedge clk_a) begin
    adr_a_pipe <= adr_a;
    dat_a_in_pipe <= dat_a_in;
    wr_a_pipe <= wr_a;
    rd_a_pipe <= rd_a;
end

// Port A pipeline stage 2
always @(posedge clk_a) begin
    if (wr_a_pipe) mem[adr_a_pipe] <= dat_a_in_pipe;
    if (rd_a_pipe) dat_a_out <= mem[adr_a_pipe];
end

// Port B pipeline stage 1
always @(posedge clk_b) begin
    adr_b_pipe <= adr_b;
    dat_b_in_pipe <= dat_b_in;
    wr_b_pipe <= wr_b;
    rd_b_pipe <= rd_b;
end

// Port B pipeline stage 2
always @(posedge clk_b) begin
    if (wr_b_pipe) mem[adr_b_pipe] <= dat_b_in_pipe;
    if (rd_b_pipe) dat_b_out <= mem[adr_b_pipe];
end

endmodule