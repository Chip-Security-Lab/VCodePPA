//SystemVerilog
module EnabledOR(
    input en,
    input [3:0] src1, 
    input [3:0] src2,
    output reg [3:0] res,
    input mul_en,
    input [3:0] mul_a,
    input [3:0] mul_b,
    output reg [7:0] mul_res
);
    // OR operation
    always @(*) begin
        if (en) begin
            res = src1 | src2;
        end else begin
            res = 4'b0000;
        end
    end

    // 4-bit Wallace Tree Multiplier
    reg [3:0] pp0, pp1, pp2, pp3;
    reg [4:0] sum1_0, sum1_1, sum1_2;
    reg [5:0] sum2_0, sum2_1;
    reg [6:0] sum3_0;
    reg [7:0] product;

    always @(*) begin
        // Generate Partial Products
        pp0 = mul_a & {4{mul_b[0]}};
        pp1 = mul_a & {4{mul_b[1]}};
        pp2 = mul_a & {4{mul_b[2]}};
        pp3 = mul_a & {4{mul_b[3]}};

        // Stage 1: Align partial products
        sum1_0 = {1'b0, pp0};
        sum1_1 = {pp1, 1'b0};
        sum1_2 = {pp2, 2'b00};
        // Stage 2: Add first three partial products
        sum2_0 = sum1_0 + sum1_1;
        sum2_1 = sum1_2 + {pp3, 3'b000};
        // Stage 3: Add the results
        sum3_0 = sum2_0 + sum2_1;
        product = {1'b0, sum3_0};

        if (mul_en) begin
            mul_res = product;
        end else begin
            mul_res = 8'b00000000;
        end
    end
endmodule