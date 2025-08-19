//SystemVerilog
module sleep_mode_clock_gate (
    input  wire sys_clk,
    input  wire sleep_req,
    input  wire wake_event,
    input  wire rst_n,
    output wire core_clk
);
    // Pipeline control signals
    reg  sleep_req_stage1, sleep_req_stage2;
    reg  wake_event_stage1, wake_event_stage2;
    
    // Sleep state registers for each pipeline stage
    reg  sleep_state_stage1, sleep_state_stage2, sleep_state_stage3;
    
    // Valid signals to track pipeline flow
    reg  valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Register inputs and initialize pipeline
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_req_stage1   <= 1'b0;
            wake_event_stage1  <= 1'b0;
            valid_stage1       <= 1'b0;
        end
        else begin
            sleep_req_stage1   <= sleep_req;
            wake_event_stage1  <= wake_event;
            valid_stage1       <= 1'b1;  // Always valid after reset
        end
    end
    
    // Stage 2: Process sleep state logic
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_req_stage2   <= 1'b0;
            wake_event_stage2  <= 1'b0;
            sleep_state_stage1 <= 1'b0;
            valid_stage2       <= 1'b0;
        end
        else begin
            sleep_req_stage2   <= sleep_req_stage1;
            wake_event_stage2  <= wake_event_stage1;
            valid_stage2       <= valid_stage1;
            
            // Sleep state calculation
            if (wake_event_stage1)
                sleep_state_stage1 <= 1'b0;
            else if (sleep_req_stage1)
                sleep_state_stage1 <= 1'b1;
            else
                sleep_state_stage1 <= sleep_state_stage1;
        end
    end
    
    // Stage 3: Second pipeline stage for sleep state
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_state_stage2 <= 1'b0;
            valid_stage3       <= 1'b0;
        end
        else begin
            sleep_state_stage2 <= sleep_state_stage1;
            valid_stage3       <= valid_stage2;
        end
    end
    
    // Stage 4: Final output stage
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_state_stage3 <= 1'b0;
        end
        else begin
            sleep_state_stage3 <= sleep_state_stage2;
        end
    end
    
    // Clock gating with deeply pipelined control signal
    // Use the final pipeline stage for actual clock gating
    assign core_clk = sys_clk & ~sleep_state_stage3;
    
endmodule