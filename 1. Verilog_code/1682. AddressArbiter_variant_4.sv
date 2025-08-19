//SystemVerilog
module AddressArbiter #(parameter AW=32) (
    input clk, rst,
    input [4*AW-1:0] addr,
    input [3:0] req,
    output reg [3:0] grant
);

wire [AW-1:0] addr_array [0:3];
wire [3:0] pri_map;
wire [3:0] shifted_pri_map;

// Extract individual addresses
assign addr_array[0] = addr[0*AW +: AW];
assign addr_array[1] = addr[1*AW +: AW];
assign addr_array[2] = addr[2*AW +: AW];
assign addr_array[3] = addr[3*AW +: AW];

// Extract priority bits from MSB of each address
assign pri_map = {
    addr_array[3][7],
    addr_array[2][7],
    addr_array[1][7],
    addr_array[0][7]
};

// Barrel shifter implementation
assign shifted_pri_map[0] = pri_map[2];
assign shifted_pri_map[1] = pri_map[3];
assign shifted_pri_map[2] = pri_map[0];
assign shifted_pri_map[3] = pri_map[1];

always @(posedge clk) 
    grant <= req & shifted_pri_map;

endmodule