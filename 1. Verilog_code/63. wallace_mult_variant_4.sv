//SystemVerilog
module wallace_mult #(parameter N=4) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);

    // Partial product generation stage
    wire [N-1:0] pp [N-1:0];
    generate
        genvar i, j;
        for(i=0; i<N; i=i+1) begin
            for(j=0; j<N; j=j+1) begin
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate

    // Stage 1: First level reduction
    wire [3:0] stage1_sum, stage1_carry;
    
    // Column 0
    assign stage1_sum[0] = pp[0][1] ^ pp[1][0];
    assign stage1_carry[0] = pp[0][1] & pp[1][0];
    
    // Column 1
    assign stage1_sum[1] = pp[0][2] ^ pp[1][1] ^ pp[2][0];
    assign stage1_carry[1] = (pp[0][2] & pp[1][1]) | (pp[0][2] & pp[2][0]) | (pp[1][1] & pp[2][0]);
    
    // Column 2
    assign stage1_sum[2] = pp[0][3] ^ pp[1][2] ^ pp[2][1] ^ pp[3][0];
    assign stage1_carry[2] = (pp[0][3] & pp[1][2]) | (pp[0][3] & pp[2][1]) | (pp[0][3] & pp[3][0]) |
                            (pp[1][2] & pp[2][1]) | (pp[1][2] & pp[3][0]) | (pp[2][1] & pp[3][0]);
    
    // Column 3
    assign stage1_sum[3] = pp[1][3] ^ pp[2][2] ^ pp[3][1];
    assign stage1_carry[3] = (pp[1][3] & pp[2][2]) | (pp[1][3] & pp[3][1]) | (pp[2][2] & pp[3][1]);

    // Stage 2: Second level reduction
    wire [3:0] stage2_sum, stage2_carry;
    
    // Column 0
    assign stage2_sum[0] = stage1_sum[0];
    assign stage2_carry[0] = stage1_carry[0];
    
    // Column 1
    assign stage2_sum[1] = stage1_sum[1] ^ stage1_carry[0];
    assign stage2_carry[1] = (stage1_sum[1] & stage1_carry[0]) | stage1_carry[1];
    
    // Column 2
    assign stage2_sum[2] = stage1_sum[2] ^ stage1_carry[1];
    assign stage2_carry[2] = (stage1_sum[2] & stage1_carry[1]) | stage1_carry[2];
    
    // Column 3
    assign stage2_sum[3] = stage1_sum[3] ^ stage1_carry[2];
    assign stage2_carry[3] = (stage1_sum[3] & stage1_carry[2]) | stage1_carry[3];

    // Stage 3: Final reduction
    wire [3:0] stage3_sum, stage3_carry;
    
    // Column 0
    assign stage3_sum[0] = stage2_sum[0];
    assign stage3_carry[0] = stage2_carry[0];
    
    // Column 1
    assign stage3_sum[1] = stage2_sum[1] ^ stage2_carry[0];
    assign stage3_carry[1] = (stage2_sum[1] & stage2_carry[0]) | stage2_carry[1];
    
    // Column 2
    assign stage3_sum[2] = stage2_sum[2] ^ stage2_carry[1];
    assign stage3_carry[2] = (stage2_sum[2] & stage2_carry[1]) | stage2_carry[2];
    
    // Column 3
    assign stage3_sum[3] = stage2_sum[3] ^ stage2_carry[2];
    assign stage3_carry[3] = (stage2_sum[3] & stage2_carry[2]) | stage2_carry[3];

    // Final addition stage
    wire [7:0] final_sum, final_carry;
    
    // Initialize sum and carry vectors
    assign final_sum[0] = pp[0][0];
    assign final_carry[0] = 1'b0;
    
    // Main product bits
    assign final_sum[1] = stage3_sum[0];
    assign final_carry[1] = stage3_carry[0];
    
    assign final_sum[2] = stage3_sum[1];
    assign final_carry[2] = stage3_carry[1];
    
    assign final_sum[3] = stage3_sum[2];
    assign final_carry[3] = stage3_carry[2];
    
    assign final_sum[4] = stage3_sum[3];
    assign final_carry[4] = stage3_carry[3];
    
    // High-order bits
    assign final_sum[5] = pp[2][3] ^ pp[3][2];
    assign final_carry[5] = pp[2][3] & pp[3][2];
    
    assign final_sum[6] = pp[3][3];
    assign final_carry[6] = 1'b0;
    
    assign final_sum[7] = 1'b0;
    assign final_carry[7] = 1'b0;

    // Final carry propagation
    wire [7:0] carry_chain;
    assign carry_chain[0] = 1'b0;
    
    generate
        for (i = 1; i < 8; i = i + 1) begin
            assign prod[i] = final_sum[i] ^ final_carry[i-1] ^ carry_chain[i-1];
            assign carry_chain[i] = (final_sum[i] & final_carry[i-1]) | 
                                  (final_sum[i] & carry_chain[i-1]) | 
                                  (final_carry[i-1] & carry_chain[i-1]);
        end
    endgenerate
    
    assign prod[0] = final_sum[0];
endmodule