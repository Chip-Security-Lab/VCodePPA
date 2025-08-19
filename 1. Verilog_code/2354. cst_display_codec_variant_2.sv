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
    // Stage 1: Input registration
    reg [3*DATA_WIDTH-1:0] in_reg_stage1;
    reg [3*3*COEF_WIDTH-1:0] matrix_reg_stage1;
    reg valid_stage1;
    
    // Matrix multiplication early calculation
    wire [DATA_WIDTH-1:0] in_color_components [2:0];
    wire [COEF_WIDTH-1:0] matrix_components [8:0];
    
    // Stage 2 signals
    reg [2*DATA_WIDTH+COEF_WIDTH-1:0] mult_results_stage2 [8:0];
    reg valid_stage2;
    
    // Stage 3 signals
    reg [DATA_WIDTH-1:0] clipped_results_stage3 [2:0];
    reg valid_stage3;
    
    // Extract input color components and matrix coefficients early
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : extract_inputs
            assign in_color_components[i] = in_color[i*DATA_WIDTH +: DATA_WIDTH];
        end
        
        for (i = 0; i < 9; i = i + 1) begin : extract_matrix
            assign matrix_components[i] = transform_matrix[i*COEF_WIDTH +: COEF_WIDTH];
        end
    endgenerate
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg_stage1 <= 0;
            matrix_reg_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            in_reg_stage1 <= in_color;
            matrix_reg_stage1 <= transform_matrix;
            valid_stage1 <= enable;
        end
    end
    
    // Stage 2: Perform multiplication and move clipping logic earlier
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < 9; k = k + 1) begin
                mult_results_stage2[k] <= 0;
            end
            valid_stage2 <= 0;
        end else begin
            for (int k = 0; k < 9; k = k + 1) begin
                mult_results_stage2[k] <= in_reg_stage1[(k%3)*DATA_WIDTH +: DATA_WIDTH] * 
                                         matrix_reg_stage1[k*COEF_WIDTH +: COEF_WIDTH];
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Perform addition and clipping in the same stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int k = 0; k < 3; k = k + 1) begin
                clipped_results_stage3[k] <= 0;
            end
            valid_stage3 <= 0;
        end else begin
            for (int k = 0; k < 3; k = k + 1) begin
                // Calculate sum
                logic [DATA_WIDTH+COEF_WIDTH:0] sum_temp;
                sum_temp = mult_results_stage2[k*3] + mult_results_stage2[k*3+1] + mult_results_stage2[k*3+2];
                
                // Clip in the same stage
                if (sum_temp > {1'b0, {DATA_WIDTH{1'b1}}}) 
                    clipped_results_stage3[k] <= {DATA_WIDTH{1'b1}};
                else if (sum_temp < 0)
                    clipped_results_stage3[k] <= {DATA_WIDTH{1'b0}};
                else
                    clipped_results_stage3[k] <= sum_temp[DATA_WIDTH-1:0];
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final output registration - moved from combinational to registered
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_color <= 0;
            valid <= 0;
        end else begin
            out_color <= {clipped_results_stage3[0], clipped_results_stage3[1], clipped_results_stage3[2]};
            valid <= valid_stage3;
        end
    end
endmodule