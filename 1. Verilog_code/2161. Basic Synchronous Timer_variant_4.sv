//SystemVerilog
module basic_sync_timer #(parameter WIDTH = 32)(
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] count,
    output reg timeout
);
    // Stage 1: Increment calculation
    reg [WIDTH-1:0] count_stage1;
    reg enable_stage1;
    
    // Stage 2: Comparison calculation
    reg [WIDTH-1:0] count_stage2;
    reg comparison_result_stage2;
    
    // Stage 3: Final output
    reg comparison_result_stage3;
    
    // Optimized increment logic with single-cycle detection
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage1 <= {WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
        end else begin
            // Optimized increment operation
            count_stage1 <= enable ? (count + 1'b1) : count;
            enable_stage1 <= enable;
        end
    end
    
    // Optimized comparison logic
    // Using AND reduction for faster comparison with all-ones pattern
    always @(posedge clk) begin
        if (!rst_n) begin
            count_stage2 <= {WIDTH{1'b0}};
            comparison_result_stage2 <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            // Optimized comparison using reduction operator
            comparison_result_stage2 <= &count_stage1;
        end
    end
    
    // Output stage with simplified logic
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
            comparison_result_stage3 <= 1'b0;
            timeout <= 1'b0;
        end else begin
            count <= count_stage2;
            comparison_result_stage3 <= comparison_result_stage2;
            // Simplified and gate logic
            timeout <= comparison_result_stage3 & enable_stage1;
        end
    end
endmodule