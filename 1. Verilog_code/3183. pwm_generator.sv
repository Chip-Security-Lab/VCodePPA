module pwm_generator #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    input [WIDTH-1:0] duty,
    output reg pwm_out
);
reg [WIDTH-1:0] counter;

always @(posedge clk) begin
    if (counter < PERIOD)
        counter <= counter + 1;
    else
        counter <= 0;

    pwm_out <= (counter < duty) ? 1'b1 : 1'b0;
end
endmodule
