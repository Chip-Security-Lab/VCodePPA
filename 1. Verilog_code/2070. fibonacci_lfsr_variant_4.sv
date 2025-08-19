//SystemVerilog
`timescale 1ns / 1ps

module fibonacci_lfsr #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [WIDTH-1:0] seed,
    input wire [WIDTH-1:0] polynomial,  // Taps as '1' bits
    output wire [WIDTH-1:0] lfsr_out,
    output wire serial_out
);

    reg [WIDTH-1:0] lfsr_reg_stage1;
    reg [WIDTH-1:0] lfsr_reg_stage2;
    reg feedback_stage1;
    reg feedback_stage2;

    // Stage 1: lfsr_reg_stage1 register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg_stage1 <= seed;
        end else if (enable) begin
            lfsr_reg_stage1 <= lfsr_reg_stage2;
        end
    end

    // Stage 1: feedback_stage1 register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feedback_stage1 <= 1'b0;
        end else if (enable) begin
            feedback_stage1 <= ^(lfsr_reg_stage2 & polynomial);
        end
    end

    // Stage 2: lfsr_reg_stage2 register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg_stage2 <= seed;
        end else if (enable) begin
            lfsr_reg_stage2 <= {feedback_stage2, lfsr_reg_stage2[WIDTH-1:1]};
        end
    end

    // Stage 2: feedback_stage2 register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feedback_stage2 <= 1'b0;
        end else if (enable) begin
            feedback_stage2 <= feedback_stage1;
        end
    end

    assign lfsr_out = lfsr_reg_stage2;
    assign serial_out = lfsr_reg_stage2[0];

endmodule