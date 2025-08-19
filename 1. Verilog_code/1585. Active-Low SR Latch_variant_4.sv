//SystemVerilog
module baugh_wooley_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);

    wire [7:0] a_ext = {a[7], a};
    wire [7:0] b_ext = {b[7], b};
    
    wire [7:0] partial_products [7:0];
    wire [7:0] sum_stage1 [3:0];
    wire [7:0] sum_stage2 [1:0];
    wire [7:0] sum_stage3;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_row
                if (i == 7 && j == 7) begin
                    assign partial_products[i][j] = ~(a_ext[i] & b_ext[j]);
                end
                else if (i == 7 || j == 7) begin
                    assign partial_products[i][j] = a_ext[i] & b_ext[j];
                end
                else begin
                    assign partial_products[i][j] = a_ext[i] & b_ext[j];
                end
            end
        end
    endgenerate
    
    // First stage of addition
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage1
            assign sum_stage1[i] = partial_products[2*i] + (partial_products[2*i+1] << 1);
        end
    endgenerate
    
    // Second stage of addition
    generate
        for (i = 0; i < 2; i = i + 1) begin : stage2
            assign sum_stage2[i] = sum_stage1[2*i] + (sum_stage1[2*i+1] << 2);
        end
    endgenerate
    
    // Final stage of addition
    assign sum_stage3 = sum_stage2[0] + (sum_stage2[1] << 4);
    
    // Output assignment
    assign product = {1'b1, sum_stage3};
    
endmodule