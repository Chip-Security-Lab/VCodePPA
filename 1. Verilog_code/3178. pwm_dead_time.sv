module pwm_dead_time(
    input clk,
    input rst,
    input [7:0] duty,
    input [3:0] dead_time,
    output reg pwm_high,
    output reg pwm_low
);
    reg [7:0] counter;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 8'd0;
            pwm_high <= 1'b0;
            pwm_low <= 1'b0;
        end else begin
            counter <= counter + 8'd1;
            pwm_high <= (counter < duty) ? 1'b1 : 1'b0;
            pwm_low <= (counter > duty + {4'd0, dead_time}) ? 1'b1 : 1'b0;
        end
    end
endmodule