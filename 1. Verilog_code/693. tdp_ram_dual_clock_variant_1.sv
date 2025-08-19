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

reg [A_WIDTH-1:0] adr_a_reg;
reg [D_WIDTH-1:0] dat_a_in_reg;
reg wr_a_reg, rd_a_reg;
reg [A_WIDTH-1:0] adr_b_reg;
reg [D_WIDTH-1:0] dat_b_in_reg;
reg wr_b_reg, rd_b_reg;

// Port A operations
always @(posedge clk_a) begin
    // Pipeline stage 1
    adr_a_reg <= adr_a;
    dat_a_in_reg <= dat_a_in;
    wr_a_reg <= wr_a;
    rd_a_reg <= rd_a;
    
    // Pipeline stage 2
    if (wr_a_reg) mem[adr_a_reg] <= dat_a_in_reg;
    if (rd_a_reg) dat_a_out <= mem[adr_a_reg];
end

// Port B operations
always @(posedge clk_b) begin
    // Pipeline stage 1
    adr_b_reg <= adr_b;
    dat_b_in_reg <= dat_b_in;
    wr_b_reg <= wr_b;
    rd_b_reg <= rd_b;
    
    // Pipeline stage 2
    if (wr_b_reg) mem[adr_b_reg] <= dat_b_in_reg;
    if (rd_b_reg) dat_b_out <= mem[adr_b_reg];
end

endmodule