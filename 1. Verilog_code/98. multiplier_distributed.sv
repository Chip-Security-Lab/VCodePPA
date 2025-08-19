module multiplier_distributed (
    input [3:0] a, 
    input [3:0] b,
    output [7:0] product
);
    wire [7:0] partial_product [3:0];
    assign partial_product[0] = a[0] ? b : 0;
    assign partial_product[1] = a[1] ? (b << 1) : 0;
    assign partial_product[2] = a[2] ? (b << 2) : 0;
    assign partial_product[3] = a[3] ? (b << 3) : 0;
    assign product = partial_product[0] + partial_product[1] + partial_product[2] + partial_product[3];
endmodule
