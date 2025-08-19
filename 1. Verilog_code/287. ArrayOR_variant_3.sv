//SystemVerilog
// Submodule to combine row and column inputs
module InputCombiner (
    input logic [3:0] row_in,
    input logic [3:0] col_in,
    output logic [7:0] combined_out
);

    assign combined_out = {row_in, col_in};

endmodule

// Submodule to perform bitwise OR operation
module BitwiseOR (
    input logic [7:0] data_in,
    output logic [7:0] data_out
);

    // Perform bitwise OR with a fixed mask
    assign data_out = data_in | 8'hAA;

endmodule

// Top module orchestrating the operations with pipelining
module ArrayOR (
    input logic clk,
    input logic reset_n,
    input logic [3:0] row,
    input logic [3:0] col,
    output logic [7:0] matrix_or
);

    // Stage 1: Input Combination
    logic [7:0] combined_data_s1;
    InputCombiner u_input_combiner (
        .row_in(row),
        .col_in(col),
        .combined_out(combined_data_s1)
    );

    // Pipeline Register between Stage 1 and Stage 2
    logic [7:0] combined_data_s2;
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) combined_data_s2 <= 8'b0;
        else combined_data_s2 <= combined_data_s1;
    end

    // Stage 2: Bitwise OR Operation
    logic [7:0] matrix_or_s2;
    BitwiseOR u_bitwise_or (
        .data_in(combined_data_s2),
        .data_out(matrix_or_s2)
    );

    // Pipeline Register for Output
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) matrix_or <= 8'b0;
        else matrix_or <= matrix_or_s2;
    end

endmodule