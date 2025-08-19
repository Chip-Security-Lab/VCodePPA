module subtractor_4bit_step (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);
    wire [3:0] b_inv;
    wire [3:0] sum;
    wire carry_out;
    
    // Invert b for subtraction
    assign b_inv = ~b;
    
    // Carry-skip adder implementation
    wire [3:0] g, p;  // Generate and propagate signals
    wire [3:0] carry;
    
    // Generate and propagate signals
    assign g[0] = a[0] & b_inv[0];
    assign p[0] = a[0] ^ b_inv[0];
    
    assign g[1] = a[1] & b_inv[1];
    assign p[1] = a[1] ^ b_inv[1];
    
    assign g[2] = a[2] & b_inv[2];
    assign p[2] = a[2] ^ b_inv[2];
    
    assign g[3] = a[3] & b_inv[3];
    assign p[3] = a[3] ^ b_inv[3];
    
    // Carry computation with skip logic
    wire skip_0_1, skip_2_3;
    
    // First block (bits 0-1)
    assign carry[0] = 1'b1;  // Initial carry for subtraction
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign skip_0_1 = p[0] & p[1];
    
    // Second block (bits 2-3)
    assign carry[2] = g[1] | (p[1] & carry[1]);
    assign carry[3] = g[2] | (p[2] & carry[2]);
    assign skip_2_3 = p[2] & p[3];
    
    // Final carry out
    assign carry_out = g[3] | (p[3] & carry[3]);
    
    // Sum computation
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ carry[1];
    assign sum[2] = p[2] ^ carry[2];
    assign sum[3] = p[3] ^ carry[3];
    
    // Output assignment
    assign diff = sum;
endmodule