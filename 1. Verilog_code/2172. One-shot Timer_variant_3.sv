//SystemVerilog
module oneshot_timer (
    input CLK, RST, TRIGGER,
    input [15:0] PERIOD,
    output reg ACTIVE, DONE
);
    // Stage 1: Edge detection pipeline
    reg trigger_d1, trigger_d2;
    reg trigger_edge_stage1;
    
    // Stage 2: Counter computation pipeline
    reg [15:0] counter_stage1, counter_stage2;
    reg active_stage1, active_stage2;
    reg done_stage1, done_stage2;
    
    // Stage 3: Comparison pipeline
    reg compare_result_stage1;
    reg [15:0] period_stage1, period_stage2;
    
    // Edge detection pipeline (Stage 1)
    always @(posedge CLK) begin
        if (RST) begin
            trigger_d1 <= 1'b0;
            trigger_d2 <= 1'b0;
            trigger_edge_stage1 <= 1'b0;
        end else begin
            trigger_d1 <= TRIGGER;
            trigger_d2 <= trigger_d1;
            trigger_edge_stage1 <= TRIGGER & ~trigger_d1;
        end
    end
    
    // Comparison preparation (Stage 1)
    always @(posedge CLK) begin
        if (RST) begin
            period_stage1 <= 16'd0;
        end else begin
            period_stage1 <= PERIOD;
        end
    end
    
    // Counter logic (Stage 2)
    always @(posedge CLK) begin
        if (RST) begin
            counter_stage1 <= 16'd0;
            active_stage1 <= 1'b0;
            done_stage1 <= 1'b0;
            period_stage2 <= 16'd0;
        end else begin
            period_stage2 <= period_stage1;
            done_stage1 <= 1'b0;
            
            if (trigger_edge_stage1 && !active_stage1) begin
                active_stage1 <= 1'b1;
                counter_stage1 <= 16'd0;
            end else if (active_stage1) begin
                counter_stage1 <= counter_stage1 + 16'd1;
            end
        end
    end
    
    // Comparison logic (Stage 3)
    always @(posedge CLK) begin
        if (RST) begin
            compare_result_stage1 <= 1'b0;
            counter_stage2 <= 16'd0;
            active_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            active_stage2 <= active_stage1;
            
            // Perform comparison in separate stage
            compare_result_stage1 <= (counter_stage1 == period_stage2 - 16'd1) && active_stage1;
        end
    end
    
    // Final output stage
    always @(posedge CLK) begin
        if (RST) begin
            ACTIVE <= 1'b0;
            DONE <= 1'b0;
            done_stage2 <= 1'b0;
        end else begin
            ACTIVE <= active_stage2;
            done_stage2 <= compare_result_stage1;
            DONE <= done_stage2;
            
            // Deactivate timer when comparison is true
            if (compare_result_stage1) begin
                ACTIVE <= 1'b0;
            end
        end
    end
endmodule