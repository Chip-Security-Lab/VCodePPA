module AddressArbiter #(parameter AW=32) (
    input clk, rst,
    input [4*AW-1:0] addr,  // 扁平化数组
    input [3:0] req,
    output reg [3:0] grant
);
wire [AW-1:0] addr_array [0:3];
wire [3:0] pri_map;

// Extract individual addresses
genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: addr_extract
        assign addr_array[g] = addr[g*AW +: AW];
    end
endgenerate

// Extract priority bits from MSB of each address
assign pri_map = {
    addr_array[3][7],  // 高优先级位
    addr_array[2][7],
    addr_array[1][7],
    addr_array[0][7]
};

always @(posedge clk) 
    grant <= req & (pri_map << 2); // $clog2(4) = 2
endmodule