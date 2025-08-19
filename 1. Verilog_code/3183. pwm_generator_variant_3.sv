//SystemVerilog
// Counter submodule
module pwm_counter #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    output reg [WIDTH-1:0] count
);

always @(posedge clk) begin
    if (count >= PERIOD)
        count <= 0;
    else
        count <= count + 1;
end

endmodule

// Comparator submodule
module pwm_comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] count,
    input [WIDTH-1:0] duty,
    output reg compare_result
);

always @(*) begin
    compare_result = (count < duty);
end

endmodule

// Top-level PWM generator module
module pwm_generator #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    input [WIDTH-1:0] duty,
    output pwm_out
);

wire [WIDTH-1:0] counter_value;
wire compare_result;

// Instantiate counter submodule
pwm_counter #(
    .WIDTH(WIDTH),
    .PERIOD(PERIOD)
) counter_inst (
    .clk(clk),
    .count(counter_value)
);

// Instantiate comparator submodule
pwm_comparator #(
    .WIDTH(WIDTH)
) comparator_inst (
    .count(counter_value),
    .duty(duty),
    .compare_result(compare_result)
);

// Output register
reg pwm_out_reg;
always @(posedge clk) begin
    pwm_out_reg <= compare_result;
end

assign pwm_out = pwm_out_reg;

endmodule