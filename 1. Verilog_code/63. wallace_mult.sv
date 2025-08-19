module wallace_mult #(parameter N=4) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);
    // Partial product generation
    wire [N-1:0] pp [N-1:0];
    generate
        genvar i, j;
        for(i=0; i<N; i=i+1) begin
            for(j=0; j<N; j=j+1) begin
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace tree reduction for N=4 implementation
    // Level 1: Generate partial products
    wire [0:0] s11, c11;  // For bit position 1
    wire [1:0] s12, c12;  // For bit position 2
    wire [2:0] s13, c13;  // For bit position 3
    wire [2:0] s14, c14;  // For bit position 4
    wire [1:0] s15, c15;  // For bit position 5
    wire [0:0] s16, c16;  // For bit position 6
    
    // First level reduction
    // Bit position 1
    assign s11[0] = pp[0][1] ^ pp[1][0];
    assign c11[0] = pp[0][1] & pp[1][0];
    
    // Bit position 2
    assign s12[0] = pp[0][2] ^ pp[1][1];
    assign c12[0] = pp[0][2] & pp[1][1];
    assign s12[1] = pp[2][0];
    assign c12[1] = 1'b0;
    
    // Bit position 3
    assign s13[0] = pp[0][3] ^ pp[1][2];
    assign c13[0] = pp[0][3] & pp[1][2];
    assign s13[1] = pp[2][1] ^ pp[3][0];
    assign c13[1] = pp[2][1] & pp[3][0];
    assign s13[2] = 1'b0;
    assign c13[2] = 1'b0;
    
    // Bit position 4
    assign s14[0] = pp[1][3] ^ pp[2][2];
    assign c14[0] = pp[1][3] & pp[2][2];
    assign s14[1] = pp[3][1];
    assign c14[1] = 1'b0;
    assign s14[2] = 1'b0;
    assign c14[2] = 1'b0;
    
    // Bit position 5
    assign s15[0] = pp[2][3] ^ pp[3][2];
    assign c15[0] = pp[2][3] & pp[3][2];
    assign s15[1] = 1'b0;
    assign c15[1] = 1'b0;
    
    // Bit position 6
    assign s16[0] = pp[3][3];
    assign c16[0] = 1'b0;
    
    // Level 2: Reduce again
    wire [0:0] s21, c21;  // For bit position 2
    wire [1:0] s22, c22;  // For bit position 3
    wire [1:0] s23, c23;  // For bit position 4
    wire [1:0] s24, c24;  // For bit position 5
    wire [0:0] s25, c25;  // For bit position 6
    
    // Bit position 2
    assign s21[0] = s12[0] ^ s12[1];
    assign c21[0] = s12[0] & s12[1];
    
    // Bit position 3
    assign s22[0] = s13[0] ^ s13[1];
    assign c22[0] = s13[0] & s13[1];
    assign s22[1] = c12[0] ^ c12[1];
    assign c22[1] = c12[0] & c12[1];
    
    // Bit position 4
    assign s23[0] = s14[0] ^ s14[1];
    assign c23[0] = s14[0] & s14[1];
    assign s23[1] = c13[0] ^ c13[1];
    assign c23[1] = c13[0] & c13[1];
    
    // Bit position 5
    assign s24[0] = s15[0] ^ s15[1];
    assign c24[0] = s15[0] & s15[1];
    assign s24[1] = c14[0] ^ c14[1];
    assign c24[1] = c14[0] & c14[1];
    
    // Bit position 6
    assign s25[0] = s16[0] ^ c15[0];
    assign c25[0] = s16[0] & c15[0];
    
    // Level 3: Final addition using ripple carry adder
    wire [7:0] final_sum, final_carry;
    
    // Bit position 0
    assign final_sum[0] = pp[0][0];
    assign final_carry[0] = 1'b0;
    
    // Bit position 1
    assign final_sum[1] = s11[0];
    assign final_carry[1] = c11[0];
    
    // Bit position 2
    assign final_sum[2] = s21[0];
    assign final_carry[2] = c21[0];
    
    // Bit position 3
    assign final_sum[3] = s22[0] ^ s22[1];
    assign final_carry[3] = (s22[0] & s22[1]) | (s22[0] & c22[0]) | (s22[1] & c22[0]);
    
    // Bit position 4
    assign final_sum[4] = s23[0] ^ s23[1];
    assign final_carry[4] = (s23[0] & s23[1]) | (s23[0] & c23[0]) | (s23[1] & c23[0]);
    
    // Bit position 5
    assign final_sum[5] = s24[0] ^ s24[1];
    assign final_carry[5] = (s24[0] & s24[1]) | (s24[0] & c24[0]) | (s24[1] & c24[0]);
    
    // Bit position 6
    assign final_sum[6] = s25[0];
    assign final_carry[6] = c25[0];
    
    // Bit position 7
    assign final_sum[7] = c16[0];
    assign final_carry[7] = 1'b0;
    
    // Final stage: propagate carries
    wire [7:0] carries;
    assign carries[0] = 1'b0;
    
    assign prod[0] = final_sum[0];
    
    generate
        for (i = 1; i < 8; i = i + 1) begin
            assign prod[i] = final_sum[i] ^ final_carry[i-1] ^ carries[i-1];
            assign carries[i] = (final_sum[i] & final_carry[i-1]) | 
                               (final_sum[i] & carries[i-1]) | 
                               (final_carry[i-1] & carries[i-1]);
        end
    endgenerate
endmodule