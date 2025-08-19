//SystemVerilog
// SystemVerilog
// Submodule: InputConcatenator_Pipeline
// Concatenates the row and col inputs with a pipeline stage.
module InputConcatenator_Pipeline (
    input logic clk,
    input logic reset,
    input logic [3:0] row_in,
    input logic [3:0] col_in,
    output logic [7:0] concatenated_out_reg
);

    logic [7:0] concatenated_comb;

    assign concatenated_comb = {row_in, col_in};

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            concatenated_out_reg <= 8'h0;
        end else begin
            concatenated_out_reg <= concatenated_comb;
        end
    end

endmodule

// Submodule: BitwiseOR_Pipeline
// Performs a bitwise OR operation with a fixed mask and a pipeline stage.
module BitwiseOR_Pipeline (
    input logic clk,
    input logic reset,
    input logic [7:0] data_in_reg,
    output logic [7:0] data_or_out_reg
);
    parameter OR_MASK = 8'hAA;

    logic [7:0] data_or_comb;

    assign data_or_comb = data_in_reg | OR_MASK;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_or_out_reg <= 8'h0;
        end else begin
            data_or_out_reg <= data_or_comb;
        end
    end

endmodule

// Top module: ArrayOR_Pipelined
// Combines row and col inputs, performs bitwise OR with a mask, with pipelining.
module ArrayOR_Pipelined (
    input logic clk,
    input logic reset,
    input logic [3:0] row,
    input logic [3:0] col,
    output logic [7:0] matrix_or_reg
);

    logic [7:0] stage1_concatenated_data_reg;

    // Instantiate the input concatenator submodule with pipeline stage
    InputConcatenator_Pipeline U_InputConcatenator_Pipeline (
        .clk(clk),
        .reset(reset),
        .row_in(row),
        .col_in(col),
        .concatenated_out_reg(stage1_concatenated_data_reg)
    );

    // Instantiate the bitwise OR submodule with pipeline stage
    BitwiseOR_Pipeline U_BitwiseOR_Pipeline (
        .clk(clk),
        .reset(reset),
        .data_in_reg(stage1_concatenated_data_reg),
        .data_or_out_reg(matrix_or_reg)
    );

endmodule