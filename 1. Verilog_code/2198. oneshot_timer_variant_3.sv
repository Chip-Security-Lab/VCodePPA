//SystemVerilog
module oneshot_timer (
    input wire clock,
    input wire reset,
    input wire trigger,
    input wire [15:0] duration,
    output reg pulse_out
);
    reg [15:0] count;
    reg active;
    reg prev_trigger;
    wire trigger_edge;
    wire duration_reached;
    
    // Fan-out buffering registers for high fan-out signal
    reg active_buf1, active_buf2;
    reg [15:0] duration_buf;
    
    // Pre-compute trigger edge detection to reduce critical path
    assign trigger_edge = trigger && !prev_trigger;
    
    // Pre-compute duration comparison to balance path delay
    assign duration_reached = (count >= duration_buf - 16'd1);
    
    // Buffer the duration input to reduce load
    always @(posedge clock) begin
        if (reset)
            duration_buf <= 16'd0;
        else
            duration_buf <= duration;
    end
    
    // Fan-out buffering for 'active' signal
    always @(posedge clock) begin
        if (reset) begin
            active_buf1 <= 1'b0;
            active_buf2 <= 1'b0;
        end else begin
            active_buf1 <= active;
            active_buf2 <= active;
        end
    end
    
    always @(posedge clock) begin
        if (reset) begin
            count <= 16'd0;
            active <= 1'b0;
            pulse_out <= 1'b0;
            prev_trigger <= 1'b0;
        end else begin
            prev_trigger <= trigger;
            
            if (trigger_edge) begin
                active <= 1'b1;
                count <= 16'd0;
                pulse_out <= 1'b1;
            end else if (active_buf1) begin
                if (duration_reached) begin
                    active <= 1'b0;
                    pulse_out <= 1'b0;
                end else begin
                    count <= count + 16'd1;
                end
            end
        end
    end
endmodule