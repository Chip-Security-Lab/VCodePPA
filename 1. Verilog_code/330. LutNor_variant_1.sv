//SystemVerilog
// Top-level module: Structured pipelined 2-input NOR using LUT structure
module LutNor(
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output wire y
);

    // Stage 1: Input registration for clear dataflow and timing closure
    reg a_stage1;
    reg b_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end

    // Stage 2: LUT calculation
    wire lut_output_stage2;

    Lut2NorLut u_lut2_nor (
        .clk    (clk),
        .rst_n  (rst_n),
        .in_a   (a_stage1),
        .in_b   (b_stage1),
        .lut_out(lut_output_stage2)
    );

    // Stage 3: Output registration for improved timing and dataflow clarity
    reg y_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_stage3 <= 1'b0;
        else
            y_stage3 <= lut_output_stage2;
    end

    // Output assignment
    assign y = y_stage3;

endmodule

// Submodule: 2-input LUT configured as NOR with pipelined output
module Lut2NorLut(
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output wire lut_out
);
    // LUT contents parameterized for flexibility
    parameter [3:0] LUT_CONTENT = 4'b1000;

    // Stage 1: Input registration for clear dataflow
    reg in_a_stage1;
    reg in_b_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_a_stage1 <= 1'b0;
            in_b_stage1 <= 1'b0;
        end else begin
            in_a_stage1 <= in_a;
            in_b_stage1 <= in_b;
        end
    end

    // Stage 2: LUT logic
    wire [1:0] lut_index_stage2;
    assign lut_index_stage2 = {in_a_stage1, in_b_stage1};

    reg lut_out_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lut_out_stage2 <= 1'b0;
        else
            lut_out_stage2 <= LUT_CONTENT[lut_index_stage2];
    end

    // Output assignment
    assign lut_out = lut_out_stage2;

endmodule