//SystemVerilog
module AddressArbiter #(parameter AW=32) (
    input clk, rst,
    input [4*AW-1:0] addr,
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
    addr_array[3][7],
    addr_array[2][7],
    addr_array[1][7],
    addr_array[0][7]
};

// Dadda multiplier implementation for 4-bit multiplication
wire [7:0] dadda_product;
wire [3:0] dadda_a = req;
wire [3:0] dadda_b = pri_map;

// Partial products generation
wire [3:0] pp0 = dadda_a & {4{dadda_b[0]}};
wire [3:0] pp1 = dadda_a & {4{dadda_b[1]}};
wire [3:0] pp2 = dadda_a & {4{dadda_b[2]}};
wire [3:0] pp3 = dadda_a & {4{dadda_b[3]}};

// First reduction stage (3:2 compressors)
wire [4:0] sum1, carry1;
wire [3:0] ha_sum, ha_carry;
wire [2:0] fa_sum, fa_carry;

// Half adders
assign ha_sum[0] = pp0[1] ^ pp1[0];
assign ha_carry[0] = pp0[1] & pp1[0];
assign ha_sum[1] = pp1[3] ^ pp2[2];
assign ha_carry[1] = pp1[3] & pp2[2];
assign ha_sum[2] = pp2[3] ^ pp3[2];
assign ha_carry[2] = pp2[3] & pp3[2];
assign ha_sum[3] = pp3[3] ^ carry1[4];
assign ha_carry[3] = pp3[3] & carry1[4];

// Full adders
assign fa_sum[0] = pp0[2] ^ pp1[1] ^ pp2[0];
assign fa_carry[0] = (pp0[2] & pp1[1]) | (pp0[2] & pp2[0]) | (pp1[1] & pp2[0]);
assign fa_sum[1] = pp0[3] ^ pp1[2] ^ pp2[1];
assign fa_carry[1] = (pp0[3] & pp1[2]) | (pp0[3] & pp2[1]) | (pp1[2] & pp2[1]);
assign fa_sum[2] = pp1[3] ^ pp2[2] ^ pp3[1];
assign fa_carry[2] = (pp1[3] & pp2[2]) | (pp1[3] & pp3[1]) | (pp2[2] & pp3[1]);

// Second reduction stage (3:2 compressors)
wire [5:0] sum2, carry2;
wire [4:0] ha_sum2, ha_carry2;
wire [3:0] fa_sum2, fa_carry2;

// Half adders
assign ha_sum2[0] = sum1[1] ^ carry1[0];
assign ha_carry2[0] = sum1[1] & carry1[0];
assign ha_sum2[1] = sum1[2] ^ carry1[1];
assign ha_carry2[1] = sum1[2] & carry1[1];
assign ha_sum2[2] = sum1[3] ^ carry1[2];
assign ha_carry2[2] = sum1[3] & carry1[2];
assign ha_sum2[3] = sum1[4] ^ carry1[3];
assign ha_carry2[3] = sum1[4] & carry1[3];
assign ha_sum2[4] = sum1[5] ^ carry1[4];
assign ha_carry2[4] = sum1[5] & carry1[4];

// Full adders
assign fa_sum2[0] = ha_sum[0] ^ ha_carry[0] ^ carry1[0];
assign fa_carry2[0] = (ha_sum[0] & ha_carry[0]) | (ha_sum[0] & carry1[0]) | (ha_carry[0] & carry1[0]);
assign fa_sum2[1] = ha_sum[1] ^ ha_carry[1] ^ carry1[1];
assign fa_carry2[1] = (ha_sum[1] & ha_carry[1]) | (ha_sum[1] & carry1[1]) | (ha_carry[1] & carry1[1]);
assign fa_sum2[2] = ha_sum[2] ^ ha_carry[2] ^ carry1[2];
assign fa_carry2[2] = (ha_sum[2] & ha_carry[2]) | (ha_sum[2] & carry1[2]) | (ha_carry[2] & carry1[2]);
assign fa_sum2[3] = ha_sum[3] ^ ha_carry[3] ^ carry1[3];
assign fa_carry2[3] = (ha_sum[3] & ha_carry[3]) | (ha_sum[3] & carry1[3]) | (ha_carry[3] & carry1[3]);

// Final addition using carry-save adder
assign dadda_product[0] = pp0[0];
assign dadda_product[1] = ha_sum2[0];
assign dadda_product[2] = ha_sum2[1] ^ ha_carry2[0];
assign dadda_product[3] = ha_sum2[2] ^ ha_carry2[1];
assign dadda_product[4] = ha_sum2[3] ^ ha_carry2[2];
assign dadda_product[5] = ha_sum2[4] ^ ha_carry2[3];
assign dadda_product[6] = fa_sum2[3] ^ ha_carry2[4];
assign dadda_product[7] = fa_carry2[3];

always @(posedge clk) 
    grant <= dadda_product[3:0];
endmodule