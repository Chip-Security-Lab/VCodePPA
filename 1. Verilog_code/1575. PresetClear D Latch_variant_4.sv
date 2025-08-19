//SystemVerilog
module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Split inputs into high and low parts
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];

    // Calculate partial products using optimized multipliers
    wire [7:0] z0;
    wire [7:0] z2;
    wire [9:0] z1;
    
    // Use dedicated 4x4 multipliers for z0 and z2
    assign z0 = {4'b0, a_low} * {4'b0, b_low};
    assign z2 = {4'b0, a_high} * {4'b0, b_high};
    
    // Optimize middle term calculation
    wire [4:0] a_sum = {1'b0, a_high} + {1'b0, a_low};
    wire [4:0] b_sum = {1'b0, b_high} + {1'b0, b_low};
    wire [9:0] sum_product = {5'b0, a_sum} * {5'b0, b_sum};
    
    // Optimize final combination
    assign z1 = sum_product - {2'b0, z0} - {2'b0, z2};
    assign product = ({8'b0, z2} << 8) + ({6'b0, z1} << 4) + {8'b0, z0};

endmodule