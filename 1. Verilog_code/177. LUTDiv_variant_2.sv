//SystemVerilog
module BaughWooleyMultiplier(input [3:0] x, y, output reg [7:0] product);
    reg [7:0] partial_products [0:3]; // Array to hold partial products
    reg [7:0] sum; // Register to hold the sum of partial products

    // Initialize partial products to zero
    always @(*) begin
        partial_products[0] = 0;
        partial_products[1] = 0;
        partial_products[2] = 0;
        partial_products[3] = 0;
    end

    // Generate partial products using Baugh-Wooley algorithm
    always @(*) begin
        partial_products[0] = (y[0] ? {4'b0000, x} : 8'b00000000);
        partial_products[1] = (y[1] ? {3'b000, x, 1'b0} : 8'b00000000);
        partial_products[2] = (y[2] ? {2'b00, x, 2'b00} : 8'b00000000);
        partial_products[3] = (y[3] ? {1'b0, x, 3'b000} : 8'b00000000);
    end

    // Sum the partial products
    always @(*) begin
        sum = partial_products[0] + partial_products[1] + 
              partial_products[2] + partial_products[3];
    end

    // Assign the product output
    always @(*) begin
        product = sum;
    end
endmodule