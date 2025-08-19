//SystemVerilog
module duty_preserve_divider (
    input wire clock_in, 
    input wire n_reset, 
    input wire [3:0] div_ratio,
    output reg clock_out
);
    // Stage 1: Counter and comparison logic
    reg [3:0] counter_stage1;
    reg compare_result_stage1;
    
    // Stage 2: Output toggle logic
    reg [3:0] counter_stage2;
    reg toggle_enable_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1 - Reset logic
    always @(negedge n_reset) begin
        if (!n_reset) begin
            counter_stage1 <= 4'd0;
            compare_result_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 1 - Counter handling
    always @(posedge clock_in) begin
        if (n_reset) begin
            valid_stage1 <= 1'b1;
            
            if (counter_stage1 >= div_ratio - 1) begin
                counter_stage1 <= 4'd0;
            end else begin
                counter_stage1 <= counter_stage1 + 1'b1;
            end
        end
    end
    
    // Stage 1 - Comparison result generation
    always @(posedge clock_in) begin
        if (n_reset) begin
            if (counter_stage1 >= div_ratio - 1) begin
                compare_result_stage1 <= 1'b1;
            end else begin
                compare_result_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2 - Reset logic
    always @(negedge n_reset) begin
        if (!n_reset) begin
            counter_stage2 <= 4'd0;
            toggle_enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            clock_out <= 1'b0;
        end
    end
    
    // Stage 2 - Pipeline control propagation
    always @(posedge clock_in) begin
        if (n_reset) begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2 - Data capture from previous stage
    always @(posedge clock_in) begin
        if (n_reset) begin
            counter_stage2 <= counter_stage1;
            toggle_enable_stage2 <= compare_result_stage1;
        end
    end
    
    // Stage 2 - Clock output toggle logic
    always @(posedge clock_in) begin
        if (n_reset) begin
            if (valid_stage2 && toggle_enable_stage2) begin
                clock_out <= ~clock_out;
            end
        end
    end
endmodule