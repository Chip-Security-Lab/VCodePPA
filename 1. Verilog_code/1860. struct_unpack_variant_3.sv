//SystemVerilog
module struct_unpack #(parameter TOTAL_W=32, FIELD_N=4) (
    input [TOTAL_W-1:0] packed_data,
    input [$clog2(FIELD_N)-1:0] select,
    output reg [TOTAL_W/FIELD_N-1:0] unpacked
);
    localparam FIELD_W = TOTAL_W / FIELD_N;

    // Intermediate signals for better pipelining
    wire [FIELD_W-1:0] selected_field;
    wire [FIELD_W-1:0] partial_products [0:FIELD_W-1];
    wire [FIELD_W*2-1:0] wallace_sum;
    wire [FIELD_W*2-1:0] wallace_carry;
    wire [FIELD_W-1:0] addition_result;

    // Field selection logic - separate functionality
    assign selected_field = packed_data[select*FIELD_W +: FIELD_W];

    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < FIELD_W; i = i + 1) begin : gen_partial_products
            for (j = 0; j < FIELD_W; j = j + 1) begin : gen_pp
                assign partial_products[i][j] = selected_field[i] & selected_field[j];
            end
        end
    endgenerate

    // Wallace tree reduction
    wallace_tree_reduction #(
        .WIDTH(FIELD_W)
    ) wallace_inst (
        .partial_products(partial_products),
        .sum(wallace_sum),
        .carry(wallace_carry)
    );

    // Final addition - separate functionality from the always block
    assign addition_result = wallace_sum[FIELD_W-1:0] + wallace_carry[FIELD_W-1:0];

    // Register output - separated timing logic
    always @(*) begin
        unpacked = addition_result;
    end

endmodule

// Improved Wallace tree reduction module
module wallace_tree_reduction #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] partial_products [0:WIDTH-1],
    output [WIDTH*2-1:0] sum,
    output [WIDTH*2-1:0] carry
);
    // Intermediate signals for better organization
    wire [WIDTH-1:0] stage1_sum [0:WIDTH-1];
    wire [WIDTH-1:0] stage1_carry [0:WIDTH-1];
    
    // First stage reduction - separate functionality
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_stage1
            for (j = 0; j < WIDTH-1; j = j + 2) begin : gen_reduction_pairs
                assign stage1_sum[i][j/2] = partial_products[i][j] ^ partial_products[i][j+1];
                assign stage1_carry[i][j/2] = partial_products[i][j] & partial_products[i][j+1];
            end
            // Handle odd width case
            if (WIDTH % 2 == 1) begin
                assign stage1_sum[i][WIDTH/2] = partial_products[i][WIDTH-1];
                assign stage1_carry[i][WIDTH/2] = 1'b0;
            end
        end
    endgenerate

    // Second stage reduction - combining first stage results
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin : gen_reduction
            assign sum[k] = stage1_sum[k][0];
            assign carry[k+1] = stage1_carry[k][0];
            
            // Additional logic for better compression
            if (k < WIDTH-1) begin : additional_compression
                assign sum[k+WIDTH] = stage1_sum[k][1] ^ stage1_carry[k][1];
                assign carry[k+WIDTH+1] = stage1_sum[k][1] & stage1_carry[k][1];
            end
        end
    endgenerate

    // Zero out unused bits
    generate
        if (WIDTH*2 > 2*WIDTH+1) begin : cleanup
            for (k = 2*WIDTH+1; k < WIDTH*2; k = k + 1) begin : zero_unused
                assign sum[k] = 1'b0;
                assign carry[k] = 1'b0;
            end
        end
    endgenerate

endmodule