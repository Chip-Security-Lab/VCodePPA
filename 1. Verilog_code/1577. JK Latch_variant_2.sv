//SystemVerilog
module karatsuba_multiplier (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    // Split inputs into high and low parts
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];

    // First level products with optimized multiplication
    wire [7:0] p0 = a_low * b_low;
    wire [7:0] p1 = a_high * b_high;
    wire [3:0] sum_a = a_high + a_low;
    wire [3:0] sum_b = b_high + b_low;
    wire [7:0] p2 = sum_a * sum_b;

    // Optimized intermediate calculations
    wire [7:0] p2_minus_p1_minus_p0 = p2 - p1 - p0;

    // Final product assembly with optimized shift operations
    wire [15:0] p1_shifted = {p1, 8'b0};
    wire [15:0] p2_shifted = {4'b0, p2_minus_p1_minus_p0, 4'b0};
    wire [15:0] p0_extended = {8'b0, p0};
    
    assign product = p1_shifted + p2_shifted + p0_extended;

endmodule