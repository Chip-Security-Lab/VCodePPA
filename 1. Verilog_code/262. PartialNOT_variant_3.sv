//SystemVerilog
// SystemVerilog
// Module: PartialNOT_Top_Pipelined
// Description: Pipelined Top-level module for Partial NOT operation.
// Combines the high byte (unchanged) and the inverted low byte.
// Introduces a pipeline stage for improved timing.
module PartialNOT_Top_Pipelined (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] word_in,
    output wire [15:0] modified_out
);

    // Internal signals for pipeline stages
    reg  [15:0] word_reg;
    wire [15:8] high_byte_stage1;
    wire [7:0]  low_byte_stage1;
    reg  [15:8] high_byte_reg;
    reg  [7:0]  low_byte_inverted_reg;

    // Stage 0: Register input word
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            word_reg <= 16'b0;
        end else begin
            word_reg <= word_in;
        end
    end

    // Stage 1: Process high and low bytes
    assign high_byte_stage1 = word_reg[15:8];
    assign low_byte_stage1  = ~word_reg[7:0]; // Invert low byte

    // Stage 2: Register processed bytes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_byte_reg <= 8'b0;
            low_byte_inverted_reg <= 8'b0;
        end else begin
            high_byte_reg <= high_byte_stage1;
            low_byte_inverted_reg <= low_byte_stage1;
        end
    end

    // Stage 3: Combine and output
    assign modified_out = {high_byte_reg, low_byte_inverted_reg};

endmodule