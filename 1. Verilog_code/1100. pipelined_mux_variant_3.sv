//SystemVerilog

module pipelined_mux (
    input wire clk,
    input wire [1:0] address,
    input wire [15:0] data_0, data_1, data_2, data_3,
    input wire [15:0] multiplier_a,
    input wire [15:0] multiplier_b,
    output reg [31:0] mul_result,
    output reg [15:0] result
);

    reg [15:0] mux_selected_data_comb;
    wire [31:0] dadda_product_comb;

    // Instantiate the multiplier module
    dadda_multiplier_16x16_optimized u_dadda_multiplier (
        .clk(clk),
        .a(multiplier_a),
        .b(multiplier_b),
        .product(dadda_product_comb)
    );

    // Merge combinational and sequential logic for pipelined MUX and multiplier result
    always @(posedge clk) begin
        // MUX selection (registered output)
        case(address)
            2'b00: mux_selected_data_comb <= data_0;
            2'b01: mux_selected_data_comb <= data_1;
            2'b10: mux_selected_data_comb <= data_2;
            2'b11: mux_selected_data_comb <= data_3;
            default: mux_selected_data_comb <= 16'b0;
        endcase
        result <= mux_selected_data_comb;

        // Register multiplier output
        mul_result <= dadda_product_comb;
    end

endmodule

module dadda_multiplier_16x16_optimized (
    input wire clk,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] product
);
    // Partial product generation (combinational)
    wire [15:0] partial_products [15:0];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign partial_products[i] = b[i] ? a : 16'b0;
        end
    endgenerate

    // Combine all reduction stages into two pipeline stages

    // Stage 1: Combine partial products into four intermediate sums
    reg [31:0] sum_stage1_0, sum_stage1_1, sum_stage1_2, sum_stage1_3;

    // Stage 2: Final sum
    always @(posedge clk) begin
        // Stage 1
        sum_stage1_0 <= {16'b0, partial_products[0]} +
                        {15'b0, partial_products[1], 1'b0} +
                        {14'b0, partial_products[2], 2'b0} +
                        {13'b0, partial_products[3], 3'b0};

        sum_stage1_1 <= {12'b0, partial_products[4], 4'b0} +
                        {11'b0, partial_products[5], 5'b0} +
                        {10'b0, partial_products[6], 6'b0} +
                        {9'b0, partial_products[7], 7'b0};

        sum_stage1_2 <= {8'b0, partial_products[8], 8'b0} +
                        {7'b0, partial_products[9], 9'b0} +
                        {6'b0, partial_products[10], 10'b0} +
                        {5'b0, partial_products[11], 11'b0};

        sum_stage1_3 <= {4'b0, partial_products[12], 12'b0} +
                        {3'b0, partial_products[13], 13'b0} +
                        {2'b0, partial_products[14], 14'b0} +
                        {1'b0, partial_products[15], 15'b0};

        // Stage 2
        product <= sum_stage1_0 + sum_stage1_1 + sum_stage1_2 + sum_stage1_3;
    end

endmodule