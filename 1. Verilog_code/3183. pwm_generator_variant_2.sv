//SystemVerilog
// Top-level module
module pwm_generator #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    input [WIDTH-1:0] duty,
    output pwm_out
);
    // Internal signals
    wire [WIDTH-1:0] counter_value;
    
    // Counter submodule instance
    counter_module #(
        .WIDTH(WIDTH),
        .PERIOD(PERIOD)
    ) counter_inst (
        .clk(clk),
        .counter_out(counter_value)
    );
    
    // Comparator submodule instance
    comparator_module #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .clk(clk),
        .counter_value(counter_value),
        .duty(duty),
        .pwm_out(pwm_out)
    );
endmodule

// Counter module - handles the period counting
module counter_module #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    output reg [WIDTH-1:0] counter_out
);
    // Initialize counter
    initial begin
        counter_out = 0;
    end
    
    // Counter logic
    always @(posedge clk) begin
        if (counter_out < PERIOD)
            counter_out <= counter_out + 1'b1;
        else
            counter_out <= 0;
    end
endmodule

// Comparator module - generates PWM signal based on duty cycle
module comparator_module #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] counter_value,
    input [WIDTH-1:0] duty,
    output reg pwm_out
);
    // PWM generation logic
    always @(posedge clk) begin
        pwm_out <= (counter_value < duty) ? 1'b1 : 1'b0;
    end
endmodule