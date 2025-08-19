module unsigned_subtractor_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff
);

    // Stage 1: Input Processing
    wire [7:0] b_comp;
    wire [7:0] p, g;
    
    assign b_comp = ~b;
    assign p = a ^ b_comp;
    assign g = a & b_comp;

    // Stage 2: First Level Prefix Computation
    wire [7:0] p_1, g_1;
    
    // Bit 0
    assign p_1[0] = p[0];
    assign g_1[0] = g[0];
    
    // Bits 1-7
    generate
        genvar i;
        for (i = 1; i < 8; i = i + 1) begin : first_level
            assign p_1[i] = p[i] & p[i-1];
            assign g_1[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate

    // Stage 3: Second Level Prefix Computation
    wire [7:0] p_2, g_2;
    
    // Bits 0-1
    assign p_2[0] = p_1[0];
    assign g_2[0] = g_1[0];
    assign p_2[1] = p_1[1];
    assign g_2[1] = g_1[1];
    
    // Bits 2-7
    generate
        for (i = 2; i < 8; i = i + 1) begin : second_level
            assign p_2[i] = p_1[i] & p_1[i-2];
            assign g_2[i] = g_1[i] | (p_1[i] & g_1[i-2]);
        end
    endgenerate

    // Stage 4: Third Level Prefix Computation
    wire [7:0] p_3, g_3;
    
    // Bits 0-3
    assign p_3[0] = p_2[0];
    assign g_3[0] = g_2[0];
    assign p_3[1] = p_2[1];
    assign g_3[1] = g_2[1];
    assign p_3[2] = p_2[2];
    assign g_3[2] = g_2[2];
    assign p_3[3] = p_2[3];
    assign g_3[3] = g_2[3];
    
    // Bits 4-7
    generate
        for (i = 4; i < 8; i = i + 1) begin : third_level
            assign p_3[i] = p_2[i] & p_2[i-4];
            assign g_3[i] = g_2[i] | (p_2[i] & g_2[i-4]);
        end
    endgenerate

    // Stage 5: Carry Generation
    wire [7:0] carry;
    assign carry[0] = 1'b1;  // Initial carry-in for subtraction
    assign carry[1] = g_3[0];
    assign carry[2] = g_3[1];
    assign carry[3] = g_3[2];
    assign carry[4] = g_3[3];
    assign carry[5] = g_3[4];
    assign carry[6] = g_3[5];
    assign carry[7] = g_3[6];

    // Stage 6: Final Difference Computation
    assign diff = p ^ carry;

endmodule