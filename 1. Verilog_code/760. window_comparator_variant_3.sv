//SystemVerilog
module window_comparator(
    input wire clk,                // Added clock for proper pipelining
    input wire rst_n,              // Added reset for pipeline registers
    input wire [11:0] data_value,
    input wire [11:0] lower_bound,
    input wire [11:0] upper_bound,
    output wire in_range,         // High when lower_bound ≤ data_value ≤ upper_bound
    output wire out_of_range,     // High when data_value < lower_bound OR data_value > upper_bound
    output wire at_boundary       // High when data_value equals either bound
);
    // Pipeline stage 1: Input registration
    reg [11:0] data_value_stage1;
    reg [11:0] lower_bound_stage1;
    reg [11:0] upper_bound_stage1;
    
    // Pipeline stage 2: Comparison results
    reg below_lower_stage2;
    reg above_upper_stage2;
    reg equal_lower_stage2;
    reg equal_upper_stage2;
    
    // Pipeline stage 3: Final outputs
    reg in_range_stage3;
    reg out_of_range_stage3;
    reg at_boundary_stage3;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_value_stage1 <= 12'b0;
            lower_bound_stage1 <= 12'b0;
            upper_bound_stage1 <= 12'b0;
        end else begin
            data_value_stage1 <= data_value;
            lower_bound_stage1 <= lower_bound;
            upper_bound_stage1 <= upper_bound;
        end
    end
    
    // Stage 2: Perform comparisons and register results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_lower_stage2 <= 1'b0;
            above_upper_stage2 <= 1'b0;
            equal_lower_stage2 <= 1'b0;
            equal_upper_stage2 <= 1'b0;
        end else begin
            below_lower_stage2 <= (data_value_stage1 < lower_bound_stage1);
            above_upper_stage2 <= (data_value_stage1 > upper_bound_stage1);
            equal_lower_stage2 <= (data_value_stage1 == lower_bound_stage1);
            equal_upper_stage2 <= (data_value_stage1 == upper_bound_stage1);
        end
    end
    
    // Stage 3: Generate final outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_of_range_stage3 <= 1'b0;
            in_range_stage3 <= 1'b0;
            at_boundary_stage3 <= 1'b0;
        end else begin
            out_of_range_stage3 <= below_lower_stage2 || above_upper_stage2;
            in_range_stage3 <= !(below_lower_stage2 || above_upper_stage2);
            at_boundary_stage3 <= equal_lower_stage2 || equal_upper_stage2;
        end
    end
    
    // Assign pipeline outputs to module outputs
    assign out_of_range = out_of_range_stage3;
    assign in_range = in_range_stage3;
    assign at_boundary = at_boundary_stage3;
    
endmodule