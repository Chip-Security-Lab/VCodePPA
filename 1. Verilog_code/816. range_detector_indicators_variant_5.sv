//SystemVerilog
module range_detector_indicators(
    input wire clk,                     // Clock input added for pipeline registers
    input wire rst_n,                   // Reset signal added for pipeline registers
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output reg in_range,
    output reg below_range,
    output reg above_range
);
    // Pipeline stage 1: Comparisons
    reg [11:0] input_value_reg;
    reg [11:0] min_threshold_reg, max_threshold_reg;
    reg below_range_stage1, above_range_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_value_reg <= 12'b0;
            min_threshold_reg <= 12'b0;
            max_threshold_reg <= 12'b0;
        end else begin
            input_value_reg <= input_value;
            min_threshold_reg <= min_threshold;
            max_threshold_reg <= max_threshold;
        end
    end
    
    // Pipeline stage 2: Compute comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_range_stage1 <= 1'b0;
            above_range_stage1 <= 1'b0;
        end else begin
            below_range_stage1 <= (input_value_reg < min_threshold_reg);
            above_range_stage1 <= (input_value_reg > max_threshold_reg);
        end
    end
    
    // Pipeline stage 3: Final output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_range <= 1'b0;
            above_range <= 1'b0;
            in_range <= 1'b0;
        end else begin
            below_range <= below_range_stage1;
            above_range <= above_range_stage1;
            in_range <= !(below_range_stage1 || above_range_stage1);
        end
    end
endmodule