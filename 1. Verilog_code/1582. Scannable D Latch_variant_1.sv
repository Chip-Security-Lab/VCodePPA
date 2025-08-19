//SystemVerilog
module dadda_multiplier_scannable (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire scan_in,
    input wire scan_en,
    input wire enable,
    output reg [15:0] q
);

    // Partial products generation with optimized AND gates
    wire [7:0][7:0] pp;
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_col
                assign pp[i][j] = a[i] & b[j];
            end
        end
    endgenerate

    // Optimized Dadda tree reduction
    // Level 1: 8:4 compressor with optimized XOR and AND gates
    wire [7:0] level1_sum;
    wire [7:0] level1_carry;
    wire [7:0] level1_cout;
    
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : level1_reduction
            wire [7:0] pp_col;
            assign pp_col = {pp[7][k], pp[6][k], pp[5][k], pp[4][k], pp[3][k], pp[2][k], pp[1][k], pp[0][k]};
            
            // Optimized XOR tree for sum
            assign level1_sum[k] = ^pp_col;
            
            // Optimized carry generation
            wire [3:0] pair_carries;
            assign pair_carries[0] = pp[0][k] & pp[1][k];
            assign pair_carries[1] = pp[2][k] & pp[3][k];
            assign pair_carries[2] = pp[4][k] & pp[5][k];
            assign pair_carries[3] = pp[6][k] & pp[7][k];
            assign level1_carry[k] = |pair_carries;
            
            // Optimized cout generation
            wire [2:0] triple_carries;
            assign triple_carries[0] = pp[0][k] & pp[1][k] & pp[2][k];
            assign triple_carries[1] = pp[3][k] & pp[4][k] & pp[5][k];
            assign triple_carries[2] = pp[6][k] & pp[7][k];
            assign level1_cout[k] = |triple_carries;
        end
    endgenerate

    // Level 2: 4:2 compressor with optimized logic
    wire [7:0] level2_sum;
    wire [7:0] level2_carry;
    
    genvar m;
    generate
        for (m = 0; m < 8; m = m + 1) begin : level2_reduction
            wire sum_xor_carry;
            assign sum_xor_carry = level1_sum[m] ^ level1_carry[m];
            assign level2_sum[m] = sum_xor_carry ^ level1_cout[m];
            assign level2_carry[m] = (level1_sum[m] & level1_carry[m]) | (level1_cout[m] & sum_xor_carry);
        end
    endgenerate

    // Final addition with optimized concatenation
    wire [15:0] mult_result;
    assign mult_result = {level2_carry, level2_sum};

    // Optimized scan mux
    wire [15:0] mux_out;
    assign mux_out = scan_en ? {8'b0, scan_in} : mult_result;

    // Output register with optimized enable logic
    always @* begin
        if (enable)
            q = mux_out;
    end

endmodule