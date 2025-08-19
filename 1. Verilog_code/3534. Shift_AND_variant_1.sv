//SystemVerilog
module Multiplier_BaughWooley(
    input [31:0] multiplicand,
    input [31:0] multiplier,
    output [63:0] product
);
    // Partial products
    wire [31:0] pp [31:0];
    wire [63:0] ext_pp [31:0];
    
    // Generate partial products using Baugh-Wooley algorithm
    genvar i, j;
    generate
        for (i = 0; i < 31; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < 31; j = j + 1) begin: gen_pp_cols
                assign pp[i][j] = multiplicand[j] & multiplier[i];
            end
            // Handle sign bit according to Baugh-Wooley algorithm
            assign pp[i][31] = ~(multiplicand[31] & multiplier[i]);
        end
        
        // Last row handling for Baugh-Wooley
        for (j = 0; j < 31; j = j + 1) begin: gen_last_row
            assign pp[31][j] = ~(multiplicand[j] & multiplier[31]);
        end
        // Corner case for sign bits
        assign pp[31][31] = multiplicand[31] & multiplier[31];
    endgenerate
    
    // Sign extend partial products for proper addition
    generate
        for (i = 0; i < 32; i = i + 1) begin: extend_pp
            assign ext_pp[i] = {{(32-i){1'b0}}, pp[i], {i{1'b0}}};
        end
    endgenerate
    
    // Add all partial products
    wire [63:0] sum;
    wire [63:0] correction_term;
    
    // Correction term for Baugh-Wooley algorithm
    assign correction_term = 64'h0000000100000000; // 2^32
    
    // Sum all partial products and add correction term
    assign sum = ext_pp[0] + ext_pp[1] + ext_pp[2] + ext_pp[3] +
                 ext_pp[4] + ext_pp[5] + ext_pp[6] + ext_pp[7] +
                 ext_pp[8] + ext_pp[9] + ext_pp[10] + ext_pp[11] +
                 ext_pp[12] + ext_pp[13] + ext_pp[14] + ext_pp[15] +
                 ext_pp[16] + ext_pp[17] + ext_pp[18] + ext_pp[19] +
                 ext_pp[20] + ext_pp[21] + ext_pp[22] + ext_pp[23] +
                 ext_pp[24] + ext_pp[25] + ext_pp[26] + ext_pp[27] +
                 ext_pp[28] + ext_pp[29] + ext_pp[30] + ext_pp[31] +
                 correction_term;
    
    // Final product
    assign product = sum;
endmodule