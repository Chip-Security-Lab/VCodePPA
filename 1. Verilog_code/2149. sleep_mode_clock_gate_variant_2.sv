//SystemVerilog
module sleep_mode_clock_gate (
    input  wire sys_clk,
    input  wire sleep_req,
    input  wire wake_event,
    input  wire rst_n,
    output wire core_clk
);
    // Stage 1: Input registration and initial processing
    reg sleep_req_stage1;
    reg wake_event_stage1;
    reg valid_stage1;
    
    // Stage 2: State evaluation
    reg sleep_req_stage2;
    reg wake_event_stage2;
    reg valid_stage2;
    reg sleep_state_stage2;
    
    // Stage 3: Clock gating output
    reg sleep_state_stage3;
    reg valid_stage3;
    
    // Pipeline stage 1: Register input signals
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_req_stage1 <= 1'b0;
            wake_event_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            sleep_req_stage1 <= sleep_req;
            wake_event_stage1 <= wake_event;
            valid_stage1 <= 1'b1;  // Data is valid after first clock cycle
        end
    end
    
    // Pipeline stage 2: State logic evaluation
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_req_stage2 <= 1'b0;
            wake_event_stage2 <= 1'b0;
            sleep_state_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            sleep_req_stage2 <= sleep_req_stage1;
            wake_event_stage2 <= wake_event_stage1;
            valid_stage2 <= valid_stage1;
            
            // State determination logic
            if (wake_event_stage1)
                sleep_state_stage2 <= 1'b0;
            else if (sleep_req_stage1)
                sleep_state_stage2 <= 1'b1;
            else
                sleep_state_stage2 <= sleep_state_stage2;
        end
    end
    
    // Pipeline stage 3: Final stage for output generation
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sleep_state_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            sleep_state_stage3 <= sleep_state_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Clock gating with pipeline result
    assign core_clk = (valid_stage3) ? (sys_clk & ~sleep_state_stage3) : sys_clk;
endmodule