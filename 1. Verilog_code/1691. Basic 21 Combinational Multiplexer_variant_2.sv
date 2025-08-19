//SystemVerilog
module basic_mux_2to1(
    input [7:0] data0, data1,
    input sel,
    output [7:0] out
);

    // Wallace tree multiplier implementation
    wire [7:0] partial_products [7:0];
    wire [7:0] sum_stage1 [3:0];
    wire [7:0] sum_stage2 [1:0];
    wire [7:0] final_sum;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_partial_products
            for (j = 0; j < 8; j = j + 1) begin : gen_pp
                assign partial_products[i][j] = data0[i] & data1[j];
            end
        end
    endgenerate

    // Stage 1: First level of reduction
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage1
            assign sum_stage1[i] = partial_products[2*i] + partial_products[2*i+1];
        end
    endgenerate

    // Stage 2: Second level of reduction
    generate
        for (i = 0; i < 2; i = i + 1) begin : stage2
            assign sum_stage2[i] = sum_stage1[2*i] + sum_stage1[2*i+1];
        end
    endgenerate

    // Final addition
    assign final_sum = sum_stage2[0] + sum_stage2[1];

    // Mux selection
    assign out = sel ? final_sum : data0;

endmodule