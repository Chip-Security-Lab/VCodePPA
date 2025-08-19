//SystemVerilog
module cst_display_codec #(
    parameter integer COEF_WIDTH = 8,
    parameter integer DATA_WIDTH = 8
) (
    input clk, rst_n, enable,
    input [3*DATA_WIDTH-1:0] in_color,
    input [3*3*COEF_WIDTH-1:0] transform_matrix,
    output reg [3*DATA_WIDTH-1:0] out_color,
    output reg valid
);
    // Register input data directly to reduce input to flop delay
    reg enable_r;
    wire [2*DATA_WIDTH+COEF_WIDTH-1:0] mult_results [8:0];
    wire [DATA_WIDTH+COEF_WIDTH:0] sums [2:0];
    wire [DATA_WIDTH-1:0] clipped [2:0];
    reg [DATA_WIDTH-1:0] clipped_r [2:0];
    reg valid_r;
    
    // Register inputs first without running through combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_r <= 0;
        end else begin
            enable_r <= enable;
        end
    end
    
    // Output registration after calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_color <= 0;
            valid <= 0;
            clipped_r[0] <= 0;
            clipped_r[1] <= 0;
            clipped_r[2] <= 0;
            valid_r <= 0;
        end else begin
            // Register clipped results
            clipped_r[0] <= clipped[0];
            clipped_r[1] <= clipped[1];
            clipped_r[2] <= clipped[2];
            valid_r <= enable_r;
            
            // Register final output
            out_color <= {clipped_r[0], clipped_r[1], clipped_r[2]};
            valid <= valid_r;
        end
    end
    
    // Matrix multiplication using Karatsuba multipliers (moved before registers)
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : rows
            for (j = 0; j < 3; j = j + 1) begin : cols
                karatsuba_mult #(
                    .WIDTH_A(DATA_WIDTH),
                    .WIDTH_B(COEF_WIDTH)
                ) mult_inst (
                    .a(in_color[j*DATA_WIDTH +: DATA_WIDTH]),
                    .b(transform_matrix[(i*3+j)*COEF_WIDTH +: COEF_WIDTH]),
                    .p(mult_results[i*3+j])
                );
            end
            
            assign sums[i] = mult_results[i*3] + mult_results[i*3+1] + mult_results[i*3+2];
            assign clipped[i] = (sums[i] > {1'b0, {DATA_WIDTH{1'b1}}}) ? {DATA_WIDTH{1'b1}} :
                               (sums[i] < 0) ? {DATA_WIDTH{1'b0}} : sums[i][DATA_WIDTH-1:0];
        end
    endgenerate
endmodule

// Recursive Karatsuba multiplier implementation
module karatsuba_mult #(
    parameter WIDTH_A = 8,
    parameter WIDTH_B = 8
) (
    input [WIDTH_A-1:0] a,
    input [WIDTH_B-1:0] b,
    output [WIDTH_A+WIDTH_B-1:0] p
);
    localparam MAX_WIDTH = (WIDTH_A > WIDTH_B) ? WIDTH_A : WIDTH_B;
    
    generate
        if (MAX_WIDTH <= 4) begin : small_mult
            // Direct multiplication for small operands
            assign p = a * b;
        end
        else begin : karatsuba_impl
            localparam HALF_A = WIDTH_A / 2;
            localparam HALF_B = WIDTH_B / 2;
            localparam REM_A = WIDTH_A - HALF_A;
            localparam REM_B = WIDTH_B - HALF_B;
            
            // Split the inputs
            wire [HALF_A-1:0] a_lo;
            wire [REM_A-1:0] a_hi;
            wire [HALF_B-1:0] b_lo;
            wire [REM_B-1:0] b_hi;
            
            assign a_lo = a[HALF_A-1:0];
            assign a_hi = a[WIDTH_A-1:HALF_A];
            assign b_lo = b[HALF_B-1:0];
            assign b_hi = b[WIDTH_B-1:HALF_B];
            
            // Compute sub-products
            wire [HALF_A+HALF_B-1:0] p_lo;       // a_lo * b_lo
            wire [REM_A+REM_B-1:0] p_hi;         // a_hi * b_hi
            wire [HALF_A+REM_B-1:0] a_lo_b_hi;   // a_lo * b_hi
            wire [REM_A+HALF_B-1:0] a_hi_b_lo;   // a_hi * b_lo
            wire [WIDTH_A+WIDTH_B-1:0] p_mid;    // Middle term
            
            // Recursive multiplication calls
            karatsuba_mult #(
                .WIDTH_A(HALF_A), 
                .WIDTH_B(HALF_B)
            ) mult_lo (
                .a(a_lo), 
                .b(b_lo), 
                .p(p_lo)
            );
            
            karatsuba_mult #(
                .WIDTH_A(REM_A), 
                .WIDTH_B(REM_B)
            ) mult_hi (
                .a(a_hi), 
                .b(b_hi), 
                .p(p_hi)
            );
            
            karatsuba_mult #(
                .WIDTH_A(HALF_A), 
                .WIDTH_B(REM_B)
            ) mult_lo_hi (
                .a(a_lo), 
                .b(b_hi), 
                .p(a_lo_b_hi)
            );
            
            karatsuba_mult #(
                .WIDTH_A(REM_A), 
                .WIDTH_B(HALF_B)
            ) mult_hi_lo (
                .a(a_hi), 
                .b(b_lo), 
                .p(a_hi_b_lo)
            );
            
            // Combine results with appropriate shifts
            wire [WIDTH_A+WIDTH_B-1:0] p_lo_ext, p_hi_ext, p_mid_ext;
            
            assign p_lo_ext = {{(WIDTH_A+WIDTH_B-HALF_A-HALF_B){1'b0}}, p_lo};
            assign p_hi_ext = {p_hi, {(HALF_A+HALF_B){1'b0}}};
            assign p_mid_ext = {{(WIDTH_A+WIDTH_B-REM_A-HALF_B-HALF_A-REM_B){1'b0}}, 
                               a_lo_b_hi + a_hi_b_lo, 
                               {(0){1'b0}}};
            
            // Final combination
            assign p = p_lo_ext + p_hi_ext + p_mid_ext;
        end
    endgenerate
endmodule