//SystemVerilog
module Multiplier3(
    input clk,
    input rst_n,
    input valid,
    input [3:0] data_a,
    input [3:0] data_b,
    output reg ready,
    output reg [7:0] mul_result
);

    // Pipeline stage 1 - Input register
    reg [3:0] data_a_stage1;
    reg [3:0] data_b_stage1;
    reg valid_stage1;

    // Pipeline stage 2 - Multiplication
    reg [7:0] mul_result_stage2;
    reg valid_stage2;

    // Pipeline stage 3 - Output register
    reg [7:0] mul_result_stage3;
    reg valid_stage3;

    // Stage 1: Input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_stage1 <= 4'b0;
            data_b_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_a_stage1 <= data_a;
            data_b_stage1 <= data_b;
            valid_stage1 <= valid;
        end
    end

    // Stage 2: Multiplication
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            mul_result_stage2 <= data_a_stage1 * data_b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            mul_result_stage3 <= mul_result_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result <= 8'b0;
            ready <= 1'b0;
        end
        else begin
            mul_result <= mul_result_stage3;
            ready <= valid_stage3;
        end
    end

endmodule