//SystemVerilog
module FunctionMultiplier(
    input [3:0] m, n,
    output [7:0] res
);
    wire [7:0] partial_products [3:0];
    wire [7:0] sum_stage1 [1:0];
    wire [7:0] sum_stage2;
    
    // Generate partial products with sign extension
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : pp_gen
            assign partial_products[i] = {4'b0, (n[i] ? m : 4'b0)} << i;
        end
    endgenerate
    
    // First stage of addition using Kogge-Stone
    KoggeStoneAdder #(.WIDTH(8)) adder1 (
        .a(partial_products[0]),
        .b(partial_products[1]),
        .sum(sum_stage1[0])
    );
    
    KoggeStoneAdder #(.WIDTH(8)) adder2 (
        .a(partial_products[2]),
        .b(partial_products[3]),
        .sum(sum_stage1[1])
    );
    
    // Final addition using Kogge-Stone
    KoggeStoneAdder #(.WIDTH(8)) adder3 (
        .a(sum_stage1[0]),
        .b(sum_stage1[1]),
        .sum(sum_stage2)
    );
    
    assign res = sum_stage2;
endmodule

module KoggeStoneAdder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] g [WIDTH:0];
    wire [WIDTH-1:0] p [WIDTH:0];
    wire [WIDTH-1:0] carry;
    
    // Generate and Propagate
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gp_gen
            assign g[0][i] = a[i] & b[i];
            assign p[0][i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Prefix computation
    genvar k, j;
    generate
        for (k = 0; k < $clog2(WIDTH); k = k + 1) begin : prefix_stage
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_bit
                if (j >= (1 << k)) begin
                    assign g[k+1][j] = g[k][j] | (p[k][j] & g[k][j-(1<<k)]);
                    assign p[k+1][j] = p[k][j] & p[k][j-(1<<k)];
                end else begin
                    assign g[k+1][j] = g[k][j];
                    assign p[k+1][j] = p[k][j];
                end
            end
        end
    endgenerate
    
    // Carry computation
    assign carry[0] = 1'b0;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry[i] = g[$clog2(WIDTH)][i-1];
        end
    endgenerate
    
    // Sum computation
    assign sum = p[0] ^ carry;
endmodule