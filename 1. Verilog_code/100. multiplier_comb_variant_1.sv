//SystemVerilog
module multiplier_comb (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    // Partial products generation
    wire [7:0][7:0] pp;
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_row
                assign pp[i][j] = a[i] & b[j];
            end
        end
    endgenerate

    // Stage 1: 8x8 to 6x8
    wire [5:0][7:0] stage1;
    generate
        for (i = 0; i < 6; i = i + 1) begin : stage1_gen
            for (j = 0; j < 8; j = j + 1) begin : stage1_row
                case (i)
                    0, 1: assign stage1[i][j] = pp[i][j];
                    2, 3: assign stage1[i][j] = pp[i+2][j];
                    default: assign stage1[i][j] = pp[i+4][j];
                endcase
            end
        end
    endgenerate

    // Stage 2: 6x8 to 4x8
    wire [3:0][7:0] stage2;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage2_gen
            for (j = 0; j < 8; j = j + 1) begin : stage2_row
                case (i)
                    0, 1: assign stage2[i][j] = stage1[i][j];
                    default: assign stage2[i][j] = stage1[i+2][j];
                endcase
            end
        end
    endgenerate

    // Stage 3: 4x8 to 3x8
    wire [2:0][7:0] stage3;
    generate
        for (i = 0; i < 3; i = i + 1) begin : stage3_gen
            for (j = 0; j < 8; j = j + 1) begin : stage3_row
                case (i)
                    0, 1: assign stage3[i][j] = stage2[i][j];
                    default: assign stage3[i][j] = stage2[i+1][j];
                endcase
            end
        end
    endgenerate

    // Final addition using carry-save adder
    wire [15:0] sum, carry;
    assign sum[0] = stage3[0][0];
    assign carry[0] = 1'b0;
    
    genvar k;
    generate
        for (k = 1; k < 16; k = k + 1) begin : final_add
            wire [2:0] bits;
            assign bits[0] = (k < 8) ? stage3[0][k] : 1'b0;
            assign bits[1] = (k < 8) ? stage3[1][k-1] : 1'b0;
            assign bits[2] = (k < 8) ? stage3[2][k-2] : 1'b0;
            
            wire [1:0] sum_bits;
            wire carry_out;
            
            assign sum_bits[0] = bits[0] ^ bits[1] ^ bits[2];
            assign carry_out = (bits[0] & bits[1]) | (bits[0] & bits[2]) | (bits[1] & bits[2]);
            
            assign sum[k] = sum_bits[0] ^ carry[k-1];
            assign carry[k] = (sum_bits[0] & carry[k-1]) | carry_out;
        end
    endgenerate

    // Final product calculation
    assign product = sum + {carry[14:0], 1'b0};

endmodule