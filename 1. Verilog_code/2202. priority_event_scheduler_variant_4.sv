//SystemVerilog
module priority_event_scheduler #(
    parameter EVENTS = 8,
    parameter TIMER_WIDTH = 16
)(
    input wire clk,
    input wire reset,
    input wire [TIMER_WIDTH-1:0] event_times [EVENTS-1:0],
    input wire [EVENTS-1:0] event_priority,
    output reg [2:0] next_event_id,
    output reg event_ready
);
    // Stage 1: Timer counters and expiration detection
    reg [TIMER_WIDTH-1:0] timers [EVENTS-1:0];
    reg [EVENTS-1:0] timer_expired_stage1;
    reg [EVENTS-1:0] event_priority_stage1;
    reg stage1_valid;
    
    // Stage 2: Priority encoding preparation
    reg [EVENTS-1:0] timer_expired_stage2;
    reg [EVENTS-1:0] event_priority_stage2;
    reg stage2_valid;
    
    // Stage 3: Priority selection outputs
    reg [EVENTS-1:0] selected_event_stage3;
    reg stage3_valid;
    
    // Optimization: Pre-compute priority-adjusted expired events
    reg [EVENTS-1:0] priority_expired_events;
    
    integer i;
    
    // Stage 1: Timer management and expiration detection - optimized decrementers
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < EVENTS; i = i + 1) begin
                timers[i] <= event_times[i];
            end
            timer_expired_stage1 <= {EVENTS{1'b0}};
            event_priority_stage1 <= {EVENTS{1'b0}};
            stage1_valid <= 1'b0;
        end else begin
            stage1_valid <= 1'b1;
            event_priority_stage1 <= event_priority;
            
            for (i = 0; i < EVENTS; i = i + 1) begin
                if (stage3_valid && selected_event_stage3[i]) begin
                    // Reset expired timer if it was selected in stage 3
                    timer_expired_stage1[i] <= 1'b0;
                    timers[i] <= event_times[i];
                end else if (|timers[i]) begin  // Non-zero timer check using reduction OR
                    timers[i] <= timers[i] - 1'b1;
                    timer_expired_stage1[i] <= (timers[i] == 16'd1);
                end
            end
        end
    end
    
    // Stage 2: Prepare for priority encoding with optimization
    always @(posedge clk) begin
        if (reset) begin
            timer_expired_stage2 <= {EVENTS{1'b0}};
            event_priority_stage2 <= {EVENTS{1'b0}};
            stage2_valid <= 1'b0;
            priority_expired_events <= {EVENTS{1'b0}};
        end else begin
            timer_expired_stage2 <= timer_expired_stage1;
            event_priority_stage2 <= event_priority_stage1;
            stage2_valid <= stage1_valid;
            
            // Pre-compute qualified events (expired AND priority)
            for (i = 0; i < EVENTS; i = i + 1) begin
                priority_expired_events[i] <= timer_expired_stage1[i] & event_priority_stage1[i];
            end
        end
    end
    
    // Stage 3: Optimized priority selection logic using priority encoder
    always @(posedge clk) begin
        if (reset) begin
            selected_event_stage3 <= {EVENTS{1'b0}};
            stage3_valid <= 1'b0;
            next_event_id <= 3'd0;
            event_ready <= 1'b0;
        end else begin
            selected_event_stage3 <= {EVENTS{1'b0}};
            stage3_valid <= 1'b0;
            event_ready <= 1'b0;
            
            if (stage2_valid && |priority_expired_events) begin
                // Optimized priority encoder - lowest index (highest priority) first
                casez (priority_expired_events)
                    8'b????_???1: begin next_event_id <= 3'd0; selected_event_stage3[0] <= 1'b1; end
                    8'b????_??10: begin next_event_id <= 3'd1; selected_event_stage3[1] <= 1'b1; end
                    8'b????_?100: begin next_event_id <= 3'd2; selected_event_stage3[2] <= 1'b1; end
                    8'b????_1000: begin next_event_id <= 3'd3; selected_event_stage3[3] <= 1'b1; end
                    8'b???1_0000: begin next_event_id <= 3'd4; selected_event_stage3[4] <= 1'b1; end
                    8'b??10_0000: begin next_event_id <= 3'd5; selected_event_stage3[5] <= 1'b1; end
                    8'b?100_0000: begin next_event_id <= 3'd6; selected_event_stage3[6] <= 1'b1; end
                    8'b1000_0000: begin next_event_id <= 3'd7; selected_event_stage3[7] <= 1'b1; end
                    default: begin next_event_id <= 3'd0; selected_event_stage3 <= {EVENTS{1'b0}}; end
                endcase
                
                stage3_valid <= 1'b1;
                event_ready <= 1'b1;
            end
        end
    end
endmodule