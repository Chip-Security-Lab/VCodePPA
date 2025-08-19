module adaptive_pwm #(
    parameter WIDTH = 8
)(
    input clk,
    input feedback,
    output reg pwm
);
reg [WIDTH-1:0] duty_cycle;
reg [WIDTH-1:0] counter;

always @(posedge clk) begin
    counter <= counter + 1;
    pwm <= (counter < duty_cycle);
    
    // 简单自适应算法
    if (feedback && duty_cycle < 8'hFF)
        duty_cycle <= duty_cycle + 1;
    else if (!feedback && duty_cycle > 8'h00)
        duty_cycle <= duty_cycle - 1;
end
endmodule
