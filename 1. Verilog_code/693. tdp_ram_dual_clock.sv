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

// Port A operations
always @(posedge clk_a) begin
    if (wr_a) mem[adr_a] <= dat_a_in;
    if (rd_a) dat_a_out <= mem[adr_a];
end

// Port B operations
always @(posedge clk_b) begin
    if (wr_b) mem[adr_b] <= dat_b_in;
    if (rd_b) dat_b_out <= mem[adr_b];
end
endmodule
