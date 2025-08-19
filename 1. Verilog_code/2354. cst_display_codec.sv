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
    reg [3*DATA_WIDTH-1:0] in_reg;
    reg en_reg;
    wire [2*DATA_WIDTH+COEF_WIDTH-1:0] mult_results [8:0];
    wire [DATA_WIDTH+COEF_WIDTH:0] sums [2:0];
    wire [DATA_WIDTH-1:0] clipped [2:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 0;
            en_reg <= 0;
            out_color <= 0;
            valid <= 0;
        end else begin
            // Input registration
            in_reg <= in_color;
            en_reg <= enable;
            
            // Output registration
            if (en_reg) begin
                out_color <= {clipped[0], clipped[1], clipped[2]};
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
    
    // Matrix multiplication (simplified - actual implementation would be more detailed)
    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : rows
            for (j = 0; j < 3; j = j + 1) begin : cols
                assign mult_results[i*3+j] = in_reg[j*DATA_WIDTH +: DATA_WIDTH] * 
                                             transform_matrix[(i*3+j)*COEF_WIDTH +: COEF_WIDTH];
            end
            
            assign sums[i] = mult_results[i*3] + mult_results[i*3+1] + mult_results[i*3+2];
            assign clipped[i] = (sums[i] > {1'b0, {DATA_WIDTH{1'b1}}}) ? {DATA_WIDTH{1'b1}} :
                               (sums[i] < 0) ? {DATA_WIDTH{1'b0}} : sums[i][DATA_WIDTH-1:0];
        end
    endgenerate
endmodule