//SystemVerilog
module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] result
);

    // Split inputs into high and low parts
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];

    // Calculate intermediate products
    wire [7:0] z0 = a_low * b_low;
    wire [7:0] z2 = a_high * b_high;
    
    // Calculate sum terms
    wire [4:0] a_sum = a_high + a_low;
    wire [4:0] b_sum = b_high + b_low;
    
    // Calculate z1
    wire [8:0] z1 = a_sum * b_sum - z0 - z2;

    // Combine results
    assign result = (z2 << 8) + (z1 << 4) + z0;

endmodule