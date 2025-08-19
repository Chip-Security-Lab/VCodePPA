//SystemVerilog
// Top level module - Subpixel Rendering System
module subpixel_render (
    input [7:0] px1, px2,
    output [7:0] px_out
);
    // Internal signals for connection between submodules
    wire [9:0] weighted_sum;
    
    // Instance of pixel weighting module
    pixel_weighting u_pixel_weighting (
        .pixel1(px1),
        .pixel2(px2),
        .sum_out(weighted_sum)
    );
    
    // Instance of normalization module
    normalization u_normalization (
        .data_in(weighted_sum),
        .data_out(px_out)
    );
    
endmodule

// Submodule for pixel weighting calculation using Baugh-Wooley multiplier
module pixel_weighting (
    input [7:0] pixel1,
    input [7:0] pixel2,
    output [9:0] sum_out
);
    // Parameters for weighting factors
    parameter WEIGHT1 = 3;
    parameter WEIGHT2 = 1;
    
    // Intermediate signals for Baugh-Wooley multiplication results
    wire [9:0] product1;
    wire [9:0] product2;
    
    // Instantiate Baugh-Wooley multipliers
    baugh_wooley_mult #(.WIDTH(8), .CONST_MULT(WEIGHT1)) bw_mult1 (
        .a(pixel1),
        .y(product1)
    );
    
    baugh_wooley_mult #(.WIDTH(8), .CONST_MULT(WEIGHT2)) bw_mult2 (
        .a(pixel2),
        .y(product2)
    );
    
    // Calculate weighted sum
    assign sum_out = product1 + product2;
    
endmodule

// Baugh-Wooley constant multiplier implementation
module baugh_wooley_mult #(
    parameter WIDTH = 8,
    parameter CONST_MULT = 1
)(
    input [WIDTH-1:0] a,
    output [WIDTH+1:0] y
);
    // Internal wires for partial products
    wire [WIDTH-1:0] pp[WIDTH-1:0];
    wire [WIDTH*2-1:0] sum;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < WIDTH-1; j = j + 1) begin: gen_pp_cols
                assign pp[i][j] = a[j] & CONST_MULT[i];
            end
            // Handle sign bit with complementation for Baugh-Wooley
            assign pp[i][WIDTH-1] = ~(a[WIDTH-1] & CONST_MULT[i]);
        end
        
        // Handle last row with sign modifications
        for (j = 0; j < WIDTH-1; j = j + 1) begin: gen_last_row
            assign pp[WIDTH-1][j] = ~(a[j] & CONST_MULT[WIDTH-1]);
        end
        // Corner term (positive)
        assign pp[WIDTH-1][WIDTH-1] = a[WIDTH-1] & CONST_MULT[WIDTH-1];
    endgenerate
    
    // Sum all partial products
    integer k, l;
    reg [WIDTH*2-1:0] sum_reg;
    
    always @(*) begin
        sum_reg = 0;
        // Add partial products
        for (k = 0; k < WIDTH; k = k + 1) begin
            for (l = 0; l < WIDTH; l = l + 1) begin
                sum_reg[k+l] = sum_reg[k+l] + pp[k][l];
            end
        end
        // Add correction term for Baugh-Wooley algorithm
        sum_reg[2*WIDTH-1] = sum_reg[2*WIDTH-1] + 1'b1;
    end
    
    assign sum = sum_reg;
    
    // Output the required bits based on module parameter
    assign y = sum[WIDTH+1:0];
    
endmodule

// Submodule for normalization operation using barrel shifter
module normalization (
    input [9:0] data_in,
    output [7:0] data_out
);
    // Parameter for normalization shift
    parameter NORM_SHIFT = 2;
    
    // Implement barrel shifter structure for right shifting
    // Stage 1: Shift by 0 or 1 bit
    wire [9:0] stage1_out;
    assign stage1_out = (NORM_SHIFT[0]) ? {1'b0, data_in[9:1]} : data_in;
    
    // Stage 2: Shift by 0 or 2 bits
    wire [9:0] stage2_out;
    assign stage2_out = (NORM_SHIFT[1]) ? {{2{1'b0}}, stage1_out[9:2]} : stage1_out;
    
    // Stage 3: Shift by 0 or 4 bits (if needed for larger shifts)
    wire [9:0] stage3_out;
    assign stage3_out = (NORM_SHIFT[2]) ? {{4{1'b0}}, stage2_out[9:4]} : stage2_out;
    
    // Output the normalized result
    assign data_out = stage3_out[7:0];
    
endmodule