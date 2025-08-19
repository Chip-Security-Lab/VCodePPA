//SystemVerilog
module incrementers (
    input [5:0] base,
    output [5:0] double,
    output [5:0] triple
);
    // Double is just a logical shift left
    assign double = base << 1;
    
    // Triple = base + double (using Kogge-Stone adder)
    wire [5:0] ks_sum;
    kogge_stone_adder #(.WIDTH(6)) ks_add (
        .a(base),
        .b(double),
        .sum(ks_sum)
    );
    
    assign triple = ks_sum;
endmodule

module kogge_stone_adder #(
    parameter WIDTH = 6
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // Generate (G) and Propagate (P) signals
    wire [WIDTH-1:0] g0, p0;
    
    // Stage 0: Initial generation of G and P
    assign g0 = a & b;           // Generate
    assign p0 = a ^ b;           // Propagate
    
    // Stage 1: Compute intermediate G and P for distance 1
    wire [WIDTH-1:0] g1, p1;
    
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
            assign p1[i] = p0[i] & p0[i-1];
        end
    endgenerate
    
    // Stage 2: Compute intermediate G and P for distance 2
    wire [WIDTH-1:0] g2, p2;
    
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    generate
        for (i = 2; i < WIDTH; i = i + 1) begin
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate
    
    // Stage 3: Compute intermediate G and P for distance 4
    wire [WIDTH-1:0] g3, p3;
    
    generate
        for (i = 0; i < 4; i = i + 1) begin
            assign g3[i] = g2[i];
            assign p3[i] = p2[i];
        end
        
        for (i = 4; i < WIDTH; i = i + 1) begin
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate
    
    // Final sum calculation
    wire [WIDTH:0] carry;
    assign carry[0] = 1'b0;  // No carry input
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign carry[i+1] = g3[i];
            assign sum[i] = p0[i] ^ carry[i];
        end
    endgenerate
    
endmodule