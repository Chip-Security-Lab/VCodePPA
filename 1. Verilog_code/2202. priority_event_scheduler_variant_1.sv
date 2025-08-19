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
    reg [TIMER_WIDTH-1:0] timers_stage1 [EVENTS-1:0];
    reg [EVENTS-1:0] timer_expired_stage1;
    
    // Buffered signals for high fanout reduction
    reg [EVENTS-1:0] timer_expired_stage1_buf1;
    reg [EVENTS-1:0] timer_expired_stage1_buf2;
    reg [EVENTS-1:0] event_priority_buf1;
    reg [EVENTS-1:0] event_priority_buf2;
    reg [TIMER_WIDTH-1:0] timers_stage1_buf [EVENTS-1:0];
    
    // Stage 2: Priority encoding preparation
    reg [EVENTS-1:0] timer_expired_stage2;
    reg [EVENTS-1:0] event_priority_stage2;
    reg stage2_valid;
    
    // Stage 3: Priority encoding and result selection
    reg [2:0] selected_event_stage3;
    reg event_found_stage3;
    reg stage3_valid;
    
    // Loop counters with buffered versions
    integer i, j;
    // Additional buffers for i counter to reduce fanout
    reg [3:0] i_buf1, i_buf2;
    // Additional buffers for j counter to reduce fanout
    reg [3:0] j_buf1, j_buf2;
    
    // Event ready buffer for feedback
    reg event_ready_buf;
    
    // Stage 1: Timer management and expiration detection
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < EVENTS; i = i + 1) begin
                timers_stage1[i] <= event_times[i];
                timers_stage1_buf[i] <= event_times[i];
            end
            timer_expired_stage1 <= {EVENTS{1'b0}};
            timer_expired_stage1_buf1 <= {EVENTS{1'b0}};
            timer_expired_stage1_buf2 <= {EVENTS{1'b0}};
            event_priority_buf1 <= {EVENTS{1'b0}};
            event_priority_buf2 <= {EVENTS{1'b0}};
            stage2_valid <= 1'b0;
            event_ready_buf <= 1'b0;
            i_buf1 <= 4'd0;
            i_buf2 <= 4'd0;
        end else begin
            stage2_valid <= 1'b1;
            
            // Buffer the event_ready signal to reduce loading
            event_ready_buf <= event_ready;
            
            for (i = 0; i < EVENTS; i = i + 1) begin
                i_buf1 <= i;
                i_buf2 <= i;
                
                if (timer_expired_stage1[i] && event_ready_buf) begin
                    // Reset expired timer after event is processed
                    timer_expired_stage1[i] <= 1'b0;
                    timers_stage1[i] <= event_times[i];
                    timers_stage1_buf[i] <= event_times[i];
                end else if (timers_stage1[i] > 0) begin
                    timers_stage1[i] <= timers_stage1[i] - 1'b1;
                    timers_stage1_buf[i] <= timers_stage1[i] - 1'b1;
                    if (timers_stage1[i] == 1) begin
                        timer_expired_stage1[i] <= 1'b1;
                    end
                end
            end
            
            // Update buffer registers for high fanout signals
            timer_expired_stage1_buf1 <= timer_expired_stage1;
            timer_expired_stage1_buf2 <= timer_expired_stage1;
            event_priority_buf1 <= event_priority;
            event_priority_buf2 <= event_priority;
        end
    end
    
    // Stage 2: Pass expired timers and priorities to stage 3
    always @(posedge clk) begin
        if (reset) begin
            timer_expired_stage2 <= {EVENTS{1'b0}};
            event_priority_stage2 <= {EVENTS{1'b0}};
            stage3_valid <= 1'b0;
        end else begin
            // Use buffered signals to reduce fanout on original signals
            timer_expired_stage2 <= timer_expired_stage1_buf1;
            event_priority_stage2 <= event_priority_buf1;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 3: Priority encoding and event selection
    always @(posedge clk) begin
        if (reset) begin
            selected_event_stage3 <= 3'd0;
            event_found_stage3 <= 1'b0;
            next_event_id <= 3'd0;
            event_ready <= 1'b0;
            j_buf1 <= 4'd0;
            j_buf2 <= 4'd0;
        end else begin
            event_found_stage3 <= 1'b0;
            
            // Priority encoder implementation with buffered signals
            for (j = 0; j < EVENTS; j = j + 1) begin
                j_buf1 <= j;
                j_buf2 <= j;
                
                if (timer_expired_stage2[j] && event_priority_stage2[j] && !event_found_stage3) begin
                    selected_event_stage3 <= j;
                    event_found_stage3 <= 1'b1;
                end
            end
            
            // Output stage
            next_event_id <= selected_event_stage3;
            event_ready <= event_found_stage3 && stage3_valid;
        end
    end
    
endmodule