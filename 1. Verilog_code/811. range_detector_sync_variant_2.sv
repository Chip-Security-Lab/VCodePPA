//SystemVerilog
module range_detector_pipeline(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire [7:0] lower_bound, upper_bound,
    output reg in_range,
    output reg valid_out
);

    // Pipeline stage 1 - Input registers
    reg [7:0] data_stage1;
    reg [7:0] lower_stage1;
    reg [7:0] upper_stage1;
    reg valid_stage1;

    // Pipeline stage 2 - Comparison
    reg compare_result_stage2;
    reg valid_stage2;

    // Pipeline stage 3 - Output
    reg in_range_stage3;
    reg valid_stage3;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'b0;
            lower_stage1 <= 8'b0;
            upper_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            lower_stage1 <= lower_bound;
            upper_stage1 <= upper_bound;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            compare_result_stage2 <= (data_stage1 >= lower_stage1) && (data_stage1 <= upper_stage1);
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            in_range_stage3 <= compare_result_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignment
    assign in_range = in_range_stage3;
    assign valid_out = valid_stage3;

endmodule