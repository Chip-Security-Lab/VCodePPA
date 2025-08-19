//SystemVerilog
module duty_cycle_clk #(
    parameter HIGH_CYCLE = 2,
    parameter TOTAL_CYCLE = 4
)(
    input  wire clk,
    input  wire rstb,
    output wire clk_out
);
    reg [7:0] cycle_counter;
    
    // Pipeline registers
    reg [7:0] counter_stage1;
    reg       comparison_result_stage1;
    reg       comparison_result_stage2;
    reg       comparison_result_stage3;
    reg       clk_out_reg;
    
    // Cycle counter logic
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            cycle_counter <= 8'd0;
        end else begin
            if (cycle_counter >= TOTAL_CYCLE - 1)
                cycle_counter <= 8'd0;
            else
                cycle_counter <= cycle_counter + 1'b1;
        end
    end
    
    // First pipeline stage: register the counter value
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            counter_stage1 <= 8'd0;
        end else begin
            counter_stage1 <= cycle_counter;
        end
    end
    
    // Second pipeline stage: compute comparison result
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            comparison_result_stage1 <= 1'b0;
        end else begin
            comparison_result_stage1 <= (counter_stage1 < HIGH_CYCLE);
        end
    end
    
    // Third pipeline stage: additional register stage
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            comparison_result_stage2 <= 1'b0;
        end else begin
            comparison_result_stage2 <= comparison_result_stage1;
        end
    end
    
    // Fourth pipeline stage: additional register stage
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            comparison_result_stage3 <= 1'b0;
        end else begin
            comparison_result_stage3 <= comparison_result_stage2;
        end
    end
    
    // Final pipeline stage: register the output
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            clk_out_reg <= 1'b0;
        end else begin
            clk_out_reg <= comparison_result_stage3;
        end
    end
    
    // Output assignment
    assign clk_out = clk_out_reg;
endmodule