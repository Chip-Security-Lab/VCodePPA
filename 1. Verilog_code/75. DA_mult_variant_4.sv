//SystemVerilog
module DA_mult (
    input [3:0] x,
    input [3:0] y,
    output [7:0] out
);
    // Distributed Arithmetic implementation for 4x4 bit multiplication
    wire [3:0] pp0, pp1, pp2, pp3;
    
    // Generate partial products
    assign pp0 = y[0] ? x : 4'b0000;
    assign pp1 = y[1] ? x : 4'b0000;
    assign pp2 = y[2] ? x : 4'b0000;
    assign pp3 = y[3] ? x : 4'b0000;
    
    // Shift partial products
    wire [7:0] shifted_pp1 = {pp1, 1'b0};
    wire [7:0] shifted_pp2 = {pp2, 2'b00};
    wire [7:0] shifted_pp3 = {pp3, 3'b000};
    
    // Brent-Kung adder implementation
    wire [7:0] sum1, sum2;
    wire [7:0] carry1, carry2;
    
    // First level addition
    brent_kung_adder #(8) adder1 (
        .a({4'b0000, pp0}),
        .b(shifted_pp1),
        .sum(sum1),
        .cout(carry1)
    );
    
    // Second level addition
    brent_kung_adder #(8) adder2 (
        .a(shifted_pp2),
        .b(shifted_pp3),
        .sum(sum2),
        .cout(carry2)
    );
    
    // Final addition
    brent_kung_adder #(8) adder3 (
        .a(sum1),
        .b(sum2),
        .sum(out),
        .cout()
    );
endmodule

module brent_kung_adder #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output cout
);
    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    assign g = a & b;
    assign p = a ^ b;
    
    // Brent-Kung prefix computation
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH-1:0] g_level2, p_level2;
    wire [WIDTH-1:0] g_level3, p_level3;
    
    // Level 1
    assign g_level1[0] = g[0];
    assign p_level1[0] = p[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign g_level1[i] = g[i] | (p[i] & g[i-1]);
            assign p_level1[i] = p[i] & p[i-1];
        end
    endgenerate
    
    // Level 2
    assign g_level2[0] = g_level1[0];
    assign p_level2[0] = p_level1[0];
    assign g_level2[1] = g_level1[1];
    assign p_level2[1] = p_level1[1];
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin
            assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
            assign p_level2[i] = p_level1[i] & p_level1[i-2];
        end
    endgenerate
    
    // Level 3
    assign g_level3[0] = g_level2[0];
    assign p_level3[0] = p_level2[0];
    assign g_level3[1] = g_level2[1];
    assign p_level3[1] = p_level2[1];
    assign g_level3[2] = g_level2[2];
    assign p_level3[2] = p_level2[2];
    assign g_level3[3] = g_level2[3];
    assign p_level3[3] = p_level2[3];
    generate
        for (i = 4; i < WIDTH; i = i + 1) begin
            assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
            assign p_level3[i] = p_level2[i] & p_level2[i-4];
        end
    endgenerate
    
    // Sum computation
    assign sum[0] = p[0];
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign sum[i] = p[i] ^ g_level3[i-1];
        end
    endgenerate
    
    assign cout = g_level3[WIDTH-1];
endmodule