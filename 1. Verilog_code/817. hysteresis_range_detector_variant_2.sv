//SystemVerilog
module hysteresis_range_detector(
    input wire clock, reset_n,
    input wire [7:0] input_data,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output reg in_valid_range
);
    // Stage 1 registers
    reg [7:0] input_data_stage1;
    reg [7:0] low_bound_stage1;
    reg [7:0] high_bound_stage1;
    reg [3:0] hysteresis_stage1;
    reg in_valid_range_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [7:0] effective_low_stage2;
    reg [7:0] effective_high_stage2;
    reg [7:0] input_data_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg in_range_now_stage3;
    reg valid_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            {input_data_stage1, low_bound_stage1, high_bound_stage1, hysteresis_stage1, in_valid_range_stage1, valid_stage1} <= 0;
        end else begin
            {input_data_stage1, low_bound_stage1, high_bound_stage1, hysteresis_stage1, in_valid_range_stage1, valid_stage1} <= 
            {input_data, low_bound, high_bound, hysteresis, in_valid_range, 1'b1};
        end
    end
    
    // Stage 2: Calculate effective bounds
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            {effective_low_stage2, effective_high_stage2, input_data_stage2, valid_stage2} <= 0;
        end else if (valid_stage1) begin
            effective_low_stage2 <= in_valid_range_stage1 ? (low_bound_stage1 - hysteresis_stage1) : low_bound_stage1;
            effective_high_stage2 <= in_valid_range_stage1 ? (high_bound_stage1 + hysteresis_stage1) : high_bound_stage1;
            input_data_stage2 <= input_data_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Optimized range check
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            {in_range_now_stage3, valid_stage3} <= 0;
        end else if (valid_stage2) begin
            in_range_now_stage3 <= ~((input_data_stage2 < effective_low_stage2) | (input_data_stage2 > effective_high_stage2));
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Final output stage
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            in_valid_range <= 1'b0;
        end else if (valid_stage3) begin
            in_valid_range <= in_range_now_stage3;
        end
    end
endmodule