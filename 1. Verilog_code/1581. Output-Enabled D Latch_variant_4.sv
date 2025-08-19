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
    wire [7:0] z0, z1, z2;
    wire [4:0] sum_a, sum_b;
    
    // z0 = a_low * b_low
    karatsuba_multiplier_4bit mult_low (
        .a(a_low),
        .b(b_low),
        .result(z0)
    );
    
    // z2 = a_high * b_high
    karatsuba_multiplier_4bit mult_high (
        .a(a_high),
        .b(b_high),
        .result(z2)
    );
    
    // sum_a = a_high + a_low
    assign sum_a = a_high + a_low;
    // sum_b = b_high + b_low
    assign sum_b = b_high + b_low;
    
    // z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2
    wire [7:0] z1_temp;
    karatsuba_multiplier_4bit mult_sum (
        .a(sum_a[3:0]),
        .b(sum_b[3:0]),
        .result(z1_temp)
    );
    assign z1 = z1_temp - z0 - z2;
    
    // Combine results
    assign result = (z2 << 8) + (z1 << 4) + z0;

endmodule

module karatsuba_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] result
);

    // Split inputs into high and low parts
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low = b[1:0];

    // Calculate intermediate products
    wire [3:0] z0, z1, z2;
    wire [2:0] sum_a, sum_b;
    
    // z0 = a_low * b_low
    assign z0 = a_low * b_low;
    
    // z2 = a_high * b_high
    assign z2 = a_high * b_high;
    
    // sum_a = a_high + a_low
    assign sum_a = a_high + a_low;
    // sum_b = b_high + b_low
    assign sum_b = b_high + b_low;
    
    // z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2
    wire [3:0] z1_temp;
    assign z1_temp = sum_a[1:0] * sum_b[1:0];
    assign z1 = z1_temp - z0 - z2;
    
    // Combine results
    assign result = (z2 << 4) + (z1 << 2) + z0;

endmodule