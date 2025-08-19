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
    integer i;
    
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < EVENTS; i = i + 1) begin
                timers[i] <= event_times[i];
            end
            timer_expired <= {EVENTS{1'b0}};
            next_event_id <= 3'd0;
            event_ready <= 1'b0;
        end else begin
            event_ready <= 1'b0;
            
            for (i = 0; i < EVENTS; i = i + 1) begin
                if (timers[i] > 0) begin
                    timers[i] <= timers[i] - 1'b1;
                    if (timers[i] == 1) begin
                        timer_expired[i] <= 1'b1;
                    end
                end
            end
            
            // Priority encoder for expired timers
            for (i = 0; i < EVENTS; i = i + 1) begin
                if (timer_expired[i] && event_priority[i]) begin
                    next_event_id <= i;
                    event_ready <= 1'b1;
                    timer_expired[i] <= 1'b0;
                    timers[i] <= event_times[i];
                end
            end
        end
    end
endmodule