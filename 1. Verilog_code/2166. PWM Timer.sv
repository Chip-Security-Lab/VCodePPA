module pwm_timer (
    input clk, rst, enable,
    input [15:0] period, duty,
    output reg pwm_out
);
    reg [15:0] counter;
    always @(posedge clk) begin
        if (rst) counter <= 16'd0;
        else if (enable) begin
            if (counter >= period - 1) counter <= 16'd0;
            else counter <= counter + 16'd1;
        end
    end
    always @(posedge clk) begin
        if (rst) pwm_out <= 1'b0;
        else if (enable) pwm_out <= (counter < duty);
    end
endmodule