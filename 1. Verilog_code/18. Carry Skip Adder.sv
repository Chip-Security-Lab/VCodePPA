module carry_skip_adder(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p = a ^ b;
    wire [4:0] c;
    
    assign c[0] = cin;
    
    // Block 0 (bits 0-1)
    assign c[1] = (a[0] & b[0]) | ((a[0] | b[0]) & c[0]);
    assign c[2] = (a[1] & b[1]) | ((a[1] | b[1]) & c[1]);
    
    // Skip logic
    wire block0_skip = p[0] & p[1];
    assign c[3] = block0_skip ? c[0] : 
                 (a[2] & b[2]) | ((a[2] | b[2]) & c[2]);
    
    assign c[4] = (a[3] & b[3]) | ((a[3] | b[3]) & c[3]);
    
    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule