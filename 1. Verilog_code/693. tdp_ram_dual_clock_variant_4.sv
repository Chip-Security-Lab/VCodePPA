//SystemVerilog
// Memory core module
module tdp_ram_core #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 8
)(
    input [A_WIDTH-1:0] addr,
    input [D_WIDTH-1:0] data_in,
    output reg [D_WIDTH-1:0] data_out,
    input wr_en,
    input rd_en,
    input clk
);

(* ram_style = "block" *) reg [D_WIDTH-1:0] mem [0:(1<<A_WIDTH)-1];

always @(posedge clk) begin
    if (wr_en) mem[addr] <= data_in;
    if (rd_en) data_out <= mem[addr];
end

endmodule

// Top-level module
module tdp_ram_dual_clock #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 8
)(
    // Port A domain
    input clk_a,
    input [A_WIDTH-1:0] adr_a,
    input [D_WIDTH-1:0] dat_a_in,
    output [D_WIDTH-1:0] dat_a_out,
    input wr_a,
    input rd_a,
    
    // Port B domain
    input clk_b,
    input [A_WIDTH-1:0] adr_b,
    input [D_WIDTH-1:0] dat_b_in,
    output [D_WIDTH-1:0] dat_b_out,
    input wr_b,
    input rd_b
);

// Port A instance
tdp_ram_core #(
    .D_WIDTH(D_WIDTH),
    .A_WIDTH(A_WIDTH)
) port_a (
    .addr(adr_a),
    .data_in(dat_a_in),
    .data_out(dat_a_out),
    .wr_en(wr_a),
    .rd_en(rd_a),
    .clk(clk_a)
);

// Port B instance
tdp_ram_core #(
    .D_WIDTH(D_WIDTH),
    .A_WIDTH(A_WIDTH)
) port_b (
    .addr(adr_b),
    .data_in(dat_b_in),
    .data_out(dat_b_out),
    .wr_en(wr_b),
    .rd_en(rd_b),
    .clk(clk_b)
);

endmodule