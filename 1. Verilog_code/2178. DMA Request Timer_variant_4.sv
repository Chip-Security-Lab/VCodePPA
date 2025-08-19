//SystemVerilog
module dma_timer #(parameter WIDTH = 24)(
    input clk, rst,
    input [WIDTH-1:0] period, threshold,
    output reg [WIDTH-1:0] count,
    output reg dma_req, period_match
);
    // Stage 1: Counter comparison and increment calculation
    reg [WIDTH-1:0] count_next_stage1;
    reg period_match_stage1;
    reg compare_result_stage1;
    
    // Stage 2: Counter update and final value preparation
    reg [WIDTH-1:0] count_stage2;
    reg period_match_stage2;
    reg compare_result_stage2;
    
    // Stage 3: Output register update
    reg compare_result_stage3;
    
    // Stage 1 logic - Calculate next count value and comparison results
    always @(posedge clk) begin
        if (rst) begin
            count_next_stage1 <= {WIDTH{1'b0}};
            period_match_stage1 <= 1'b0;
            compare_result_stage1 <= 1'b0;
        end
        else begin
            // Compare with period
            if (count == period - 1) begin
                count_next_stage1 <= {WIDTH{1'b0}};
                period_match_stage1 <= 1'b1;
            end
            else begin
                count_next_stage1 <= count + 1'b1;
                period_match_stage1 <= 1'b0;
            end
            
            // Compare with threshold (pipelined)
            compare_result_stage1 <= (count == threshold - 1);
        end
    end
    
    // Stage 2 logic - Pass values through pipeline
    always @(posedge clk) begin
        if (rst) begin
            count_stage2 <= {WIDTH{1'b0}};
            period_match_stage2 <= 1'b0;
            compare_result_stage2 <= 1'b0;
        end
        else begin
            count_stage2 <= count_next_stage1;
            period_match_stage2 <= period_match_stage1;
            compare_result_stage2 <= compare_result_stage1;
        end
    end
    
    // Stage 3 logic - Final stage pipeline registers
    always @(posedge clk) begin
        if (rst) begin
            count <= {WIDTH{1'b0}};
            period_match <= 1'b0;
            compare_result_stage3 <= 1'b0;
        end
        else begin
            count <= count_stage2;
            period_match <= period_match_stage2;
            compare_result_stage3 <= compare_result_stage2;
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (rst)
            dma_req <= 1'b0;
        else
            dma_req <= compare_result_stage3;
    end
endmodule