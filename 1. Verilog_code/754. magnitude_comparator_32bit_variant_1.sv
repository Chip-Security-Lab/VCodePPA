//SystemVerilog
// Top-level module for 32-bit magnitude comparator
module magnitude_comparator_32bit(
    input [31:0] a_vector,
    input [31:0] b_vector,
    output [1:0] comp_result  // 2'b00: equal, 2'b01: a<b, 2'b10: a>b
);
    wire [1:0] comparison_result;

    // Instantiate the comparison logic submodule
    comparison_logic comp_logic (
        .a_vector(a_vector),
        .b_vector(b_vector),
        .result(comparison_result)
    );

    assign comp_result = comparison_result;

endmodule

// Submodule for comparison logic
module comparison_logic(
    input [31:0] a_vector,
    input [31:0] b_vector,
    output reg [1:0] result  // 2'b00: equal, 2'b01: a<b, 2'b10: a>b
);

    always @(*) begin
        if (a_vector == b_vector)
            result = 2'b00;  // Equal
        else if (a_vector > b_vector)
            result = 2'b10;  // A greater than B
        else
            result = 2'b01;  // A less than B
    end

endmodule