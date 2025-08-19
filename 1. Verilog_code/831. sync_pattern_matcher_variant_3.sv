//SystemVerilog
module sync_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    input valid_in,
    output reg valid_out,
    output reg match_out
);
    // Stage 1 - Input registration and comparison
    reg [WIDTH-1:0] data_stage1, pattern_stage1;
    reg valid_stage1;
    reg comparison_result_stage1;
    
    // Stage 2 - Output preparation
    reg valid_stage2;
    reg comparison_result_stage2;
    
    // Stage 1 Pipeline Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            pattern_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            comparison_result_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            pattern_stage1 <= pattern;
            valid_stage1 <= valid_in;
            comparison_result_stage1 <= (data_in == pattern);
        end
    end
    
    // Stage 2 Pipeline Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            comparison_result_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            comparison_result_stage2 <= comparison_result_stage1;
        end
    end
    
    // Output Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            match_out <= comparison_result_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule