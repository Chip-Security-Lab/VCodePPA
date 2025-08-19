//SystemVerilog
module wallace_mult #(parameter N=4) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);

    // Partial Product Generation Stage
    wire [N-1:0] pp [N-1:0];
    generate
        genvar i, j;
        for(i=0; i<N; i=i+1) begin
            for(j=0; j<N; j=j+1) begin
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate

    // Stage 1: Initial Reduction
    wire [3:0] stage1_sum, stage1_carry;
    wire [1:0] stage1_temp_sum2, stage1_temp_carry2;
    wire [1:0] stage1_temp_sum3, stage1_temp_carry3;
    wire [1:0] stage1_temp_sum4, stage1_temp_carry4;
    wire [1:0] stage1_temp_sum5, stage1_temp_carry5;

    // Bit position 1-2
    assign stage1_sum[0] = pp[0][1] ^ pp[1][0];
    assign stage1_carry[0] = pp[0][1] & pp[1][0];

    // Bit position 2-3
    assign stage1_temp_sum2[0] = pp[0][2] ^ pp[1][1];
    assign stage1_temp_carry2[0] = pp[0][2] & pp[1][1];
    assign stage1_temp_sum2[1] = pp[2][0];

    // Bit position 3-4
    assign stage1_temp_sum3[0] = pp[0][3] ^ pp[1][2];
    assign stage1_temp_carry3[0] = pp[0][3] & pp[1][2];
    assign stage1_temp_sum3[1] = pp[2][1] ^ pp[3][0];
    assign stage1_temp_carry3[1] = pp[2][1] & pp[3][0];

    // Bit position 4-5
    assign stage1_temp_sum4[0] = pp[1][3] ^ pp[2][2];
    assign stage1_temp_carry4[0] = pp[1][3] & pp[2][2];
    assign stage1_temp_sum4[1] = pp[3][1];

    // Bit position 5-6
    assign stage1_temp_sum5[0] = pp[2][3] ^ pp[3][2];
    assign stage1_temp_carry5[0] = pp[2][3] & pp[3][2];
    assign stage1_temp_sum5[1] = pp[3][3];

    // Stage 2: Intermediate Reduction
    wire [5:0] stage2_sum, stage2_carry;
    wire [1:0] stage2_sum3, stage2_carry3;
    wire [1:0] stage2_sum4, stage2_carry4;
    wire [1:0] stage2_sum5, stage2_carry5;

    // Bit position 2-3
    assign stage2_sum[0] = stage1_temp_sum2[0] ^ stage1_temp_sum2[1];
    assign stage2_carry[0] = stage1_temp_sum2[0] & stage1_temp_sum2[1];

    // Bit position 3-4
    assign stage2_sum3[0] = stage1_temp_sum3[0] ^ stage1_temp_sum3[1];
    assign stage2_carry3[0] = stage1_temp_sum3[0] & stage1_temp_sum3[1];
    assign stage2_sum3[1] = stage1_temp_carry2[0];

    // Bit position 4-5
    assign stage2_sum4[0] = stage1_temp_sum4[0] ^ stage1_temp_sum4[1];
    assign stage2_carry4[0] = stage1_temp_sum4[0] & stage1_temp_sum4[1];
    assign stage2_sum4[1] = stage1_temp_carry3[0] ^ stage1_temp_carry3[1];
    assign stage2_carry4[1] = stage1_temp_carry3[0] & stage1_temp_carry3[1];

    // Bit position 5-6
    assign stage2_sum5[0] = stage1_temp_sum5[0] ^ stage1_temp_sum5[1];
    assign stage2_carry5[0] = stage1_temp_sum5[0] & stage1_temp_sum5[1];
    assign stage2_sum5[1] = stage1_temp_carry4[0];

    // Stage 3: Final Reduction
    wire [7:0] final_sum, final_carry;
    
    // Bit position 0-1
    assign final_sum[0] = pp[0][0];
    assign final_carry[0] = 1'b0;
    assign final_sum[1] = stage1_sum[0];
    assign final_carry[1] = stage1_carry[0];

    // Bit position 2-3
    assign final_sum[2] = stage2_sum[0];
    assign final_carry[2] = stage2_carry[0];
    assign final_sum[3] = stage2_sum3[0] ^ stage2_sum3[1];
    assign final_carry[3] = (stage2_sum3[0] & stage2_sum3[1]) | 
                          (stage2_sum3[0] & stage2_carry3[0]) | 
                          (stage2_sum3[1] & stage2_carry3[0]);

    // Bit position 4-5
    assign final_sum[4] = stage2_sum4[0] ^ stage2_sum4[1];
    assign final_carry[4] = (stage2_sum4[0] & stage2_sum4[1]) | 
                          (stage2_sum4[0] & stage2_carry4[0]) | 
                          (stage2_sum4[1] & stage2_carry4[0]);
    assign final_sum[5] = stage2_sum5[0] ^ stage2_sum5[1];
    assign final_carry[5] = (stage2_sum5[0] & stage2_sum5[1]) | 
                          (stage2_sum5[0] & stage2_carry5[0]) | 
                          (stage2_sum5[1] & stage2_carry5[0]);

    // Bit position 6-7
    assign final_sum[6] = stage1_temp_carry5[0];
    assign final_carry[6] = 1'b0;
    assign final_sum[7] = 1'b0;
    assign final_carry[7] = 1'b0;

    // Stage 4: Final Carry Propagation
    wire [7:0] carries;
    assign carries[0] = 1'b0;
    assign prod[0] = final_sum[0];
    
    generate
        for (genvar i = 1; i < 8; i = i + 1) begin
            wire temp_carry;
            assign temp_carry = final_sum[i] & (final_carry[i-1] | carries[i-1]);
            assign prod[i] = final_sum[i] ^ final_carry[i-1] ^ carries[i-1];
            assign carries[i] = temp_carry | (final_carry[i-1] & carries[i-1]);
        end
    endgenerate

endmodule