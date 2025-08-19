//SystemVerilog
module RangeDetector_StatCounter #(
    parameter WIDTH = 8,
    parameter CNT_WIDTH = 16
)(
    input clk, rst_n, clear,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] min_val,
    input [WIDTH-1:0] max_val,
    output reg [CNT_WIDTH-1:0] valid_count
);
    // Register inputs to improve timing
    reg [WIDTH-1:0] data_in_reg, min_val_reg, max_val_reg;
    reg clear_reg;
    
    // Split the range detection into two separate comparisons
    // to be computed in parallel, reducing critical path
    reg min_check, max_check;
    
    // First stage: register all inputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_in_reg <= 0;
            min_val_reg <= 0;
            max_val_reg <= 0;
            clear_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            min_val_reg <= min_val;
            max_val_reg <= max_val;
            clear_reg <= clear;
        end
    end
    
    // Second stage: compute range detection components separately
    // This breaks the sequential comparison logic into parallel paths
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            min_check <= 0;
            max_check <= 0;
        end else begin
            min_check <= (data_in_reg >= min_val_reg);
            max_check <= (data_in_reg <= max_val_reg);
        end
    end
    
    // Third stage: combine the parallel comparisons
    reg in_range_reg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            in_range_reg <= 0;
        else
            in_range_reg <= min_check && max_check;
    end
    
    // Pre-compute increment value to reduce adder complexity
    reg [CNT_WIDTH-1:0] next_count;
    always @(*) begin
        next_count = valid_count + 1'b1;
    end
    
    // Final stage: update counter with optimized control logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            valid_count <= 0;
        else if(clear_reg)
            valid_count <= 0;
        else if(in_range_reg)
            valid_count <= next_count;
    end
endmodule