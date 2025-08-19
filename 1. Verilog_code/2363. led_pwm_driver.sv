module led_pwm_driver #(parameter W=8)(
    input clk, 
    input [W-1:0] duty,
    output reg pwm_out
);
reg [W-1:0] cnt;
always @(posedge clk) begin
    cnt <= cnt + 1;
    pwm_out <= (cnt < duty);
end
endmodule