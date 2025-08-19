//SystemVerilog
module magnitude_comparator_32bit(
    input [31:0] a_vector,
    input [31:0] b_vector,
    output reg [1:0] comp_result  // 2'b00: equal, 2'b01: a<b, 2'b10: a>b
);

    // Intermediate signals for comparison results
    wire equal;
    wire greater;

    // Register to hold comparison results
    reg equal_reg;
    reg greater_reg;

    // 使用位级比较提高效率
    assign equal = (a_vector == b_vector);
    assign greater = (a_vector > b_vector);

    // Sequential logic to store comparison results
    always @(*) begin
        equal_reg = equal;
        greater_reg = greater;
    end

    // 组合逻辑生成最终结果
    always @(*) begin
        comp_result[0] = ~equal_reg & ~greater_reg; // a_vector == b_vector
        comp_result[1] = ~equal_reg & greater_reg;  // a_vector > b_vector
    end
endmodule