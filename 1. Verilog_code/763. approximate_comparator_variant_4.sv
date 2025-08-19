//SystemVerilog
module approximate_comparator #(
    parameter WIDTH = 12,
    parameter TOLERANCE = 3  // Default tolerance of ±3
)(
    input wire clk,                     // Clock signal for pipeline registers
    input wire rst_n,                   // Active-low reset
    input wire [WIDTH-1:0] value_a,
    input wire [WIDTH-1:0] value_b,
    input wire [WIDTH-1:0] custom_tolerance, // Optional custom tolerance value
    input wire use_custom_tolerance,         // Use custom tolerance instead of parameter
    output reg approximate_match            // High when values are within tolerance
);
    // Pipeline stage 1: Select tolerance and register inputs
    reg [WIDTH-1:0] value_a_r1, value_b_r1;
    reg [WIDTH-1:0] effective_tolerance_r1;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            value_a_r1 <= {WIDTH{1'b0}};
            value_b_r1 <= {WIDTH{1'b0}};
            effective_tolerance_r1 <= {WIDTH{1'b0}};
        end else begin
            value_a_r1 <= value_a;
            value_b_r1 <= value_b;
            effective_tolerance_r1 <= use_custom_tolerance ? custom_tolerance : TOLERANCE;
        end
    end
    
    // Pipeline stage 2: Compute difference with improved arithmetic path
    reg [WIDTH-1:0] difference_r2;
    reg value_a_greater_r2;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            difference_r2 <= {WIDTH{1'b0}};
            value_a_greater_r2 <= 1'b0;
        end else begin
            // Determine which value is greater and calculate temporary differences
            value_a_greater_r2 <= value_a_r1 > value_b_r1;
            if (value_a_r1 > value_b_r1) begin
                difference_r2 <= value_a_r1 - value_b_r1;
            end else begin
                difference_r2 <= value_b_r1 - value_a_r1;
            end
        end
    end
    
    // Pipeline stage 3: Compare difference with tolerance
    reg [WIDTH-1:0] effective_tolerance_r2;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            effective_tolerance_r2 <= {WIDTH{1'b0}};
            approximate_match <= 1'b0;
        end else begin
            effective_tolerance_r2 <= effective_tolerance_r1;
            approximate_match <= (difference_r2 <= effective_tolerance_r2);
        end
    end

endmodule