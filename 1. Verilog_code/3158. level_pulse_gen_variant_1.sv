//SystemVerilog
module level_pulse_gen (
    input clock,
    input trigger,
    input [3:0] pulse_width,
    output pulse
);
    wire trigger_detected;
    wire timer_done;
    wire [3:0] count_value;
    wire pulse_internal;
    wire start_timer;
    wire reset_system;

    trigger_detector u_trigger_detector (
        .clock(clock),
        .trigger(trigger),
        .trigger_detected(trigger_detected)
    );

    pulse_controller u_pulse_controller (
        .clock(clock),
        .trigger_detected(trigger_detected),
        .timer_done(timer_done),
        .start_timer(start_timer),
        .reset_system(reset_system),
        .pulse(pulse_internal)
    );

    pulse_timer u_pulse_timer (
        .clock(clock),
        .start_timer(start_timer),
        .reset_system(reset_system),
        .pulse_width(pulse_width),
        .count_value(count_value),
        .timer_done(timer_done)
    );

    assign pulse = pulse_internal;
endmodule

module trigger_detector (
    input clock,
    input trigger,
    output reg trigger_detected
);
    reg trigger_prev;

    always @(posedge clock) begin
        trigger_prev <= trigger;
        trigger_detected <= trigger && !trigger_prev;
    end
endmodule

module pulse_controller (
    input clock,
    input trigger_detected,
    input timer_done,
    output reg start_timer,
    output reg reset_system,
    output reg pulse
);
    localparam IDLE = 2'b00;
    localparam PULSE_ON = 2'b01;
    localparam PULSE_RESET = 2'b10;
    
    reg [1:0] state, next_state;
    
    always @(posedge clock) begin
        state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        if (state == IDLE && trigger_detected)
            next_state = PULSE_ON;
        else if (state == PULSE_ON && timer_done)
            next_state = PULSE_RESET;
        else if (state == PULSE_RESET)
            next_state = IDLE;
        else
            next_state = IDLE;
    end
    
    always @(posedge clock) begin
        if (state == IDLE) begin
            pulse <= 1'b0;
            start_timer <= 1'b0;
            reset_system <= 1'b0;
            if (trigger_detected) begin
                pulse <= 1'b1;
                start_timer <= 1'b1;
            end
        end
        else if (state == PULSE_ON) begin
            start_timer <= 1'b0;
            if (timer_done) begin
                pulse <= 1'b0;
                reset_system <= 1'b1;
            end
        end
        else if (state == PULSE_RESET) begin
            reset_system <= 1'b0;
        end
        else begin
            pulse <= 1'b0;
            start_timer <= 1'b0;
            reset_system <= 1'b0;
        end
    end
endmodule

module pulse_timer (
    input clock,
    input start_timer,
    input reset_system,
    input [3:0] pulse_width,
    output reg [3:0] count_value,
    output reg timer_done
);
    always @(posedge clock) begin
        if (reset_system || start_timer) begin
            count_value <= 4'd0;
            timer_done <= 1'b0;
        end
        else if (count_value == pulse_width - 1) begin
            timer_done <= 1'b1;
        end
        else if (!timer_done) begin
            count_value <= count_value + 1'b1;
        end
    end
endmodule