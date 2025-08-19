//SystemVerilog
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
    wire counter_reset;
    
    // Instantiate counter module
    counter_module #(
        .WIDTH(WIDTH),
        .PERIOD(PERIOD)
    ) counter_inst (
        .clk(clk),
        .counter_value(counter_value),
        .counter_reset(counter_reset)
    );
    
    // Instantiate comparator module
    comparator_module #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .clk(clk),
        .counter_value(counter_value),
        .duty(duty),
        .pwm_out(pwm_out)
    );
    
endmodule

// Counter module - handles counter operations
module counter_module #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    output reg [WIDTH-1:0] counter_value,
    output reg counter_reset
);
    // Initialize counter
    initial begin
        counter_value = 0;
        counter_reset = 0;
    end
    
    // Counter logic
    always @(posedge clk) begin
        if (counter_value < PERIOD) begin
            counter_value <= counter_value + 1;
            counter_reset <= 0;
        end
        else begin
            counter_value <= 0;
            counter_reset <= 1;
        end
    end
endmodule

// Comparator module - compares counter with duty cycle
module comparator_module #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] counter_value,
    input [WIDTH-1:0] duty,
    output reg pwm_out
);
    // PWM output generation
    always @(posedge clk) begin
        pwm_out <= (counter_value < duty) ? 1'b1 : 1'b0;
    end
endmodule