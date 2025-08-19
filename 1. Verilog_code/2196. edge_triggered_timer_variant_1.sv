//SystemVerilog
module edge_triggered_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire reset_n,
    input wire trigger,
    input wire [WIDTH-1:0] duration,
    output reg timer_active,
    output reg timeout
);
    // Pipeline stage 1 registers - Edge detection and initialization
    reg trigger_prev_stage1;
    reg trigger_edge_stage1;
    reg timer_active_stage1;
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] duration_stage1;
    
    // Pipeline stage 2 registers - Counter processing
    reg timer_active_stage2;
    reg [WIDTH-1:0] counter_stage2;
    reg [WIDTH-1:0] duration_stage2;
    reg reached_target_stage2;
    
    // Pipeline stage 3 registers - Output generation
    reg timer_active_stage3;
    reg timeout_stage3;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Edge detection and initialization
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            trigger_prev_stage1 <= 1'b0;
            trigger_edge_stage1 <= 1'b0;
            timer_active_stage1 <= 1'b0;
            counter_stage1 <= {WIDTH{1'b0}};
            duration_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            trigger_prev_stage1 <= trigger;
            trigger_edge_stage1 <= trigger & ~trigger_prev_stage1;
            
            // Register duration input for better timing
            duration_stage1 <= duration;
            
            // Initialize counter and active flag on trigger edge
            if (trigger & ~trigger_prev_stage1) begin
                counter_stage1 <= {WIDTH{1'b0}};
                timer_active_stage1 <= 1'b1;
            end else if (valid_stage2 && timer_active_stage2) begin
                // Feedback from stage 2
                timer_active_stage1 <= timer_active_stage2;
                counter_stage1 <= counter_stage2;
            end
            
            valid_stage1 <= 1'b1; // Always valid after reset
        end
    end
    
    // Stage 2: Counter processing
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            timer_active_stage2 <= 1'b0;
            counter_stage2 <= {WIDTH{1'b0}};
            duration_stage2 <= {WIDTH{1'b0}};
            reached_target_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // Pass through initialization values on trigger edge
            if (trigger_edge_stage1) begin
                timer_active_stage2 <= 1'b1;
                counter_stage2 <= {WIDTH{1'b0}};
                duration_stage2 <= duration_stage1;
                reached_target_stage2 <= 1'b0;
            end else if (timer_active_stage1) begin
                // Normal timer operation
                timer_active_stage2 <= timer_active_stage1;
                duration_stage2 <= duration_stage1;
                
                // Increment counter and check if target reached
                counter_stage2 <= counter_stage1 + 1'b1;
                reached_target_stage2 <= (counter_stage1 + 1'b1) >= (duration_stage1 - 1'b1);
            end else begin
                // Maintain current state
                timer_active_stage2 <= timer_active_stage1;
                counter_stage2 <= counter_stage1;
                duration_stage2 <= duration_stage1;
                reached_target_stage2 <= 1'b0;
            end
            
            valid_stage2 <= 1'b1;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            timer_active_stage3 <= 1'b0;
            timeout_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            if (trigger_edge_stage1) begin
                // Reset outputs on new trigger
                timer_active_stage3 <= 1'b1;
                timeout_stage3 <= 1'b0;
            end else if (timer_active_stage2 && reached_target_stage2) begin
                // Timer completed
                timer_active_stage3 <= 1'b0;
                timeout_stage3 <= 1'b1;
            end else begin
                // Maintain current state
                timer_active_stage3 <= timer_active_stage2;
                timeout_stage3 <= timeout_stage3;
            end
            
            valid_stage3 <= 1'b1;
        end
    end
    
    // Connect pipeline outputs to module outputs
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            timer_active <= 1'b0;
            timeout <= 1'b0;
        end else if (valid_stage3) begin
            timer_active <= timer_active_stage3;
            timeout <= timeout_stage3;
        end
    end
endmodule