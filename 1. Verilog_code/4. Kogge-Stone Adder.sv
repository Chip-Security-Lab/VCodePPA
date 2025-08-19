module kogge_stone_adder #(parameter N = 4) (
    input  logic [N-1:0] A,
    input  logic [N-1:0] B,
    output logic [N-1:0] Sum,
    output logic         CarryOut
);

    logic [N-1:0] G, P;         // Generate and Propagate
    logic [N:0]   C;            // Carry (include CarryIn at C[0])

    assign G = A & B;
    assign P = A ^ B;
    assign C[0] = 1'b0;         // Assuming no initial carry-in

    // Stage 1
    logic [N-1:0] g1, p1;
    assign g1 = G;
    assign p1 = P;

    // Stage 2
    logic [N-1:0] g2, p2;
    genvar i;
    generate
        for (i = 1; i < N; i = i + 1) begin
            assign g2[i] = g1[i] | (p1[i] & g1[i-1]);
            assign p2[i] = p1[i] & p1[i-1];
        end
        assign g2[0] = g1[0];
        assign p2[0] = p1[0];
    endgenerate

    // Stage 3
    logic [N-1:0] g3, p3;
    generate
        for (i = 2; i < N; i = i + 1) begin
            assign g3[i] = g2[i] | (p2[i] & g2[i-2]);
            assign p3[i] = p2[i] & p2[i-2];
        end
        assign g3[0] = g2[0];
        assign g3[1] = g2[1];
        assign p3[0] = p2[0];
        assign p3[1] = p2[1];
    endgenerate

    // Stage 4
    logic [N-1:0] g4;
    assign g4 = {g3[N-1], g2[N-2], g1[N-3], 1'sd0};  // Fixed: specify width

    // Compute carry-out
    assign C[N] = g4[N-1];

    // Compute Sum
    assign Sum = P ^ C[N-1:0];
    assign CarryOut = C[N];

endmodule
