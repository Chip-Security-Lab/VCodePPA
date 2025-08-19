//SystemVerilog
module EnabledOR(
    input en,
    input signed [3:0] src1, src2,
    output reg [3:0] res
);

    wire signed [3:0] operand_a = src1;
    wire signed [3:0] operand_b = src2;
    reg signed [7:0] partial_product [3:0];
    reg signed [7:0] mul_result;

    always @(*) begin
        // Unrolled loop for partial product generation
        if (operand_b[0]) begin
            partial_product[0] = operand_a <<< 0;
        end else begin
            partial_product[0] = 8'd0;
        end

        if (operand_b[1]) begin
            partial_product[1] = operand_a <<< 1;
        end else begin
            partial_product[1] = 8'd0;
        end

        if (operand_b[2]) begin
            partial_product[2] = operand_a <<< 2;
        end else begin
            partial_product[2] = 8'd0;
        end

        if (operand_b[3]) begin
            partial_product[3] = operand_a <<< 3;
        end else begin
            partial_product[3] = 8'd0;
        end

        mul_result = partial_product[0] + partial_product[1] + partial_product[2] + partial_product[3];

        if (en) begin
            res = mul_result[3:0];
        end else begin
            res = 4'b0000;
        end
    end

endmodule