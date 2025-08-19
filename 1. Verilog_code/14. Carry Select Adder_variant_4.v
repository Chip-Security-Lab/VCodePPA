module carry_select_adder(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);

    wire [3:0] g, p;
    wire [3:0] carry;
    wire [3:0] carry_sel;
    
    // Optimized generate and propagate signals
    assign g = a & b;
    assign p = a ^ b;
    
    // Optimized carry chain using carry select logic
    assign carry_sel[0] = cin;
    assign carry_sel[1] = g[0] | (p[0] & carry_sel[0]);
    assign carry_sel[2] = g[1] | (p[1] & carry_sel[1]);
    assign carry_sel[3] = g[2] | (p[2] & carry_sel[2]);
    
    // Parallel carry computation
    assign carry[0] = carry_sel[0];
    assign carry[1] = carry_sel[1];
    assign carry[2] = carry_sel[2];
    assign carry[3] = carry_sel[3];
    
    // Optimized sum calculation using carry select
    assign sum = p ^ {carry[2:0], cin};
    assign cout = g[3] | (p[3] & carry[3]);

endmodule