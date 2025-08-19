module pwm_generator #(parameter CNT_W=8) (
    input clk, rst, 
    input [CNT_W-1:0] duty_cycle,
    output reg pwm_out
);
reg [CNT_W-1:0] cnt;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt <= 0;
        pwm_out <= 0;
    end else begin
        cnt <= cnt + 1;
        pwm_out <= (cnt < duty_cycle);
    end
end
endmodule