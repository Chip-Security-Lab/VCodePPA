//SystemVerilog
module dadda_multiplier (
    input [7:0] data_a,
    input [7:0] data_b,
    output reg [15:0] product
);

// Internal signals for partial products and intermediate sums
wire [7:0] partial_products[0:7];
wire [15:0] sum[0:4];
wire [4:0] carry;

// Generate partial products
genvar i, j;
generate
    for (i = 0; i < 8; i = i + 1) begin : pp_gen
        assign partial_products[i] = data_a[i] ? data_b : 8'b0;
    end
endgenerate

// Dadda reduction tree
assign sum[0] = partial_products[0] + partial_products[1];
assign sum[1] = partial_products[2] + partial_products[3];
assign sum[2] = partial_products[4] + partial_products[5];
assign sum[3] = partial_products[6] + partial_products[7];

// Carry generation
assign carry[0] = sum[0][0] & sum[1][0];
assign carry[1] = sum[0][1] & sum[1][1];
assign carry[2] = sum[0][2] & sum[1][2];
assign carry[3] = sum[0][3] & sum[1][3];
assign carry[4] = sum[0][4] & sum[1][4];

// Final product calculation
always @(*) begin
    product = sum[0] + sum[1] + sum[2] + sum[3] + carry;
end

endmodule