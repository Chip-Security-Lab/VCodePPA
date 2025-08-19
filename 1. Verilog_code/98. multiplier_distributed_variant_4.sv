//SystemVerilog
module multiplier_distributed (
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    wire [7:0] partial_product [3:0];
    wire [7:0] product_reg;
    
    assign partial_product[0] = {4'b0, b} & {8{a[0]}};
    assign partial_product[1] = {3'b0, b, 1'b0} & {8{a[1]}};
    assign partial_product[2] = {2'b0, b, 2'b0} & {8{a[2]}};
    assign partial_product[3] = {1'b0, b, 3'b0} & {8{a[3]}};
    
    assign product_reg = partial_product[0] + partial_product[1] + 
                        partial_product[2] + partial_product[3];
    
    assign product = product_reg;
endmodule