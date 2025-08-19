module pwm_codec #(parameter RES=10) (
    input clk, rst,
    input [RES-1:0] duty,
    output reg pwm_out
);
    reg [RES-1:0] cnt;
    always @(posedge clk or posedge rst) begin
        if(rst) cnt <= 0;
        else cnt <= cnt + 1;
    end
    always @(negedge clk) begin
        pwm_out <= (cnt < duty);
    end
endmodule