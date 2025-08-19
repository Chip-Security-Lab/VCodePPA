//SystemVerilog
module programmable_pulse #(
    parameter WIDTH = 16
)(
    input clk,
    input [WIDTH-1:0] period,
    input [WIDTH-1:0] pulse_width,
    output reg pulse
);
reg [WIDTH-1:0] counter;
wire period_match;
wire pulse_active;

assign period_match = (counter == period - 1);
assign pulse_active = (counter < pulse_width);

always @(posedge clk) begin
    counter <= period_match ? '0 : counter + 1;
    pulse <= pulse_active;
end
endmodule