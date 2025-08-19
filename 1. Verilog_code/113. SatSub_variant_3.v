module KaratsubaMult(input [7:0] a, b, output [7:0] res);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [7:0] temp1, temp2;
    
    // Split operands into high and low halves
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // First level of Karatsuba recursion
    KaratsubaMult4bit mult0(a_low, b_low, z0);
    KaratsubaMult4bit mult1(a_high, b_high, z1);
    
    // Calculate (a_high + a_low)(b_high + b_low)
    wire [4:0] sum_a, sum_b;
    wire [7:0] z12;
    
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    KaratsubaMult4bit mult2(sum_a[3:0], sum_b[3:0], z12);
    
    // Calculate z2 = (a_high + a_low)(b_high + b_low) - z0 - z1
    assign z2 = z12 - z0 - z1;
    
    // Combine results
    assign res = (z1 << 8) + (z2 << 4) + z0;
endmodule

module KaratsubaMult4bit(input [3:0] a, b, output [7:0] res);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z1, z2;
    
    // Split operands into high and low halves
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // Second level of Karatsuba recursion
    KaratsubaMult2bit mult0(a_low, b_low, z0);
    KaratsubaMult2bit mult1(a_high, b_high, z1);
    
    // Calculate (a_high + a_low)(b_high + b_low)
    wire [2:0] sum_a, sum_b;
    wire [3:0] z12;
    
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    KaratsubaMult2bit mult2(sum_a[1:0], sum_b[1:0], z12);
    
    // Calculate z2 = (a_high + a_low)(b_high + b_low) - z0 - z1
    assign z2 = z12 - z0 - z1;
    
    // Combine results
    assign res = (z1 << 4) + (z2 << 2) + z0;
endmodule

module KaratsubaMult2bit(input [1:0] a, b, output [3:0] res);
    // Base case: 2x2 bit multiplication
    wire [3:0] partial_products [1:0];
    
    assign partial_products[0] = {2'b00, a[0] & b[0], a[0] & b[1]};
    assign partial_products[1] = {1'b0, a[1] & b[0], a[1] & b[1], 1'b0};
    
    assign res = partial_products[0] + partial_products[1];
endmodule

module SatSub(input [7:0] a, b, output reg [7:0] res);
    always @(*) res = (a >= b) ? (a - b) : 8'h0;
endmodule