module programmable_pulse #(
    parameter WIDTH = 16
)(
    input clk,
    input [WIDTH-1:0] period,
    input [WIDTH-1:0] pulse_width,
    output reg pulse
);
reg [WIDTH-1:0] counter;

always @(posedge clk) begin
    if (counter < period-1)
        counter <= counter + 1;
    else
        counter <= 0;

    pulse <= (counter < pulse_width) ? 1'b1 : 1'b0;
end
endmodule
