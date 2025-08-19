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
    reg [TIMER_WIDTH-1:0] timers [EVENTS-1:0];
    reg [EVENTS-1:0] timer_expired;
    reg [EVENTS-1:0] active_events;
    integer i;
    
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < EVENTS; i = i + 1) begin
                timers[i] <= event_times[i];
            end
            timer_expired <= {EVENTS{1'b0}};
            next_event_id <= 3'd0;
            event_ready <= 1'b0;
            active_events <= {EVENTS{1'b0}};
        end else begin
            event_ready <= 1'b0;
            
            // Timer decrement and expiration logic
            for (i = 0; i < EVENTS; i = i + 1) begin
                if (timers[i] == 1) begin
                    timers[i] <= 0;
                    timer_expired[i] <= 1'b1;
                end else if (timers[i] > 0) begin
                    timers[i] <= timers[i] - 1'b1;
                end
            end
            
            // Generate active events mask - priority AND expired
            active_events <= timer_expired & event_priority;
            
            // Optimized priority encoder
            if (active_events[7]) begin
                next_event_id <= 3'd7;
                event_ready <= 1'b1;
                timer_expired[7] <= 1'b0;
                timers[7] <= event_times[7];
            end else if (active_events[6]) begin
                next_event_id <= 3'd6;
                event_ready <= 1'b1;
                timer_expired[6] <= 1'b0;
                timers[6] <= event_times[6];
            end else if (active_events[5]) begin
                next_event_id <= 3'd5;
                event_ready <= 1'b1;
                timer_expired[5] <= 1'b0;
                timers[5] <= event_times[5];
            end else if (active_events[4]) begin
                next_event_id <= 3'd4;
                event_ready <= 1'b1;
                timer_expired[4] <= 1'b0;
                timers[4] <= event_times[4];
            end else if (active_events[3]) begin
                next_event_id <= 3'd3;
                event_ready <= 1'b1;
                timer_expired[3] <= 1'b0;
                timers[3] <= event_times[3];
            end else if (active_events[2]) begin
                next_event_id <= 3'd2;
                event_ready <= 1'b1;
                timer_expired[2] <= 1'b0;
                timers[2] <= event_times[2];
            end else if (active_events[1]) begin
                next_event_id <= 3'd1;
                event_ready <= 1'b1;
                timer_expired[1] <= 1'b0;
                timers[1] <= event_times[1];
            end else if (active_events[0]) begin
                next_event_id <= 3'd0;
                event_ready <= 1'b1;
                timer_expired[0] <= 1'b0;
                timers[0] <= event_times[0];
            end
        end
    end
endmodule