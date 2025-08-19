//SystemVerilog
module multiplier_comb (
    input clk,
    input rst_n,
    input valid,
    output ready,
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    reg [15:0] product_reg;
    reg ready_reg;
    wire [15:0] dadda_product;
    wire valid_ready;

    assign valid_ready = valid & ready_reg;

    dadda_multiplier_8x8_opt dadda_inst (
        .a(a),
        .b(b),
        .product(dadda_product)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 16'd0;
            ready_reg <= 1'b0;
        end else begin
            product_reg <= valid_ready ? dadda_product : product_reg;
            ready_reg <= !valid;
        end
    end

    assign product = product_reg;
    assign ready = ready_reg;

endmodule

module dadda_multiplier_8x8_opt (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);

    wire [7:0] pp [7:0];
    wire [15:0] sum1 [3:0];
    wire [15:0] sum2 [1:0];
    wire [15:0] final_sum;

    // Optimized partial product generation with pipelining
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_row
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate

    // Balanced reduction stages
    dadda_reduction_stage1_opt stage1 (
        .pp(pp),
        .sum(sum1)
    );

    dadda_reduction_stage2_opt stage2 (
        .sum_in(sum1),
        .sum(sum2)
    );

    // Optimized final addition with carry lookahead
    dadda_final_add_opt final_add (
        .sum_in(sum2),
        .sum(final_sum)
    );

    assign product = final_sum;

endmodule

module dadda_reduction_stage1_opt (
    input [7:0] pp [7:0],
    output [15:0] sum [3:0]
);

    // Optimized first stage reduction with balanced paths
    wire [15:0] temp_sum [7:0];
    
    // Parallel computation of intermediate sums
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : sum_gen
            assign temp_sum[i*2] = {8'b0, pp[i*2]} + {8'b0, pp[i*2+1]};
            assign temp_sum[i*2+1] = {8'b0, pp[i*2+1]} + {8'b0, pp[i*2+2]};
        end
    endgenerate

    // Balanced reduction
    assign sum[0] = temp_sum[0] + temp_sum[1];
    assign sum[1] = temp_sum[2] + temp_sum[3];
    assign sum[2] = temp_sum[4] + temp_sum[5];
    assign sum[3] = temp_sum[6] + temp_sum[7];

endmodule

module dadda_reduction_stage2_opt (
    input [15:0] sum_in [3:0],
    output [15:0] sum [1:0]
);

    // Optimized second stage reduction with balanced paths
    wire [15:0] temp_sum [1:0];
    
    // Parallel computation
    assign temp_sum[0] = sum_in[0] + sum_in[1];
    assign temp_sum[1] = sum_in[2] + sum_in[3];
    
    // Balanced output assignment
    assign sum[0] = temp_sum[0];
    assign sum[1] = temp_sum[1];

endmodule

module dadda_final_add_opt (
    input [15:0] sum_in [1:0],
    output [15:0] sum
);

    // Optimized final addition with carry lookahead
    wire [15:0] carry;
    wire [15:0] sum_temp;
    
    // Generate and propagate signals
    assign carry = sum_in[0] & sum_in[1];
    assign sum_temp = sum_in[0] ^ sum_in[1];
    
    // Final sum with carry lookahead
    assign sum = sum_temp + (carry << 1);

endmodule