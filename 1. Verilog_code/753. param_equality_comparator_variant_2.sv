//SystemVerilog
module param_equality_comparator_pipeline #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg match_flag
);

    // Stage 1: Comparison stage
    wire is_equal_stage1;
    reg valid_stage1, valid_stage2;

    // Asynchronous comparison logic
    assign is_equal_stage1 = (data_in_a == data_in_b);

    // Pipeline registers
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            match_flag <= 1'b0;
        end else if (enable) begin
            valid_stage1 <= 1'b1;
            match_flag <= is_equal_stage1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Output stage
    always @(posedge clock) begin
        if (valid_stage1) begin
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Final output logic
    always @(posedge clock) begin
        if (valid_stage2) begin
            match_flag <= match_flag; // Hold previous value when not enabled
        end
    end

endmodule