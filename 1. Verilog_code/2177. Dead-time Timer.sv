module deadtime_timer (
    input wire clk, rst_n,
    input wire [15:0] period, duty,
    input wire [7:0] deadtime,
    output reg pwm_high, pwm_low
);
    reg [15:0] counter;
    wire compare_match;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) counter <= 16'd0;
        else counter <= (counter >= period - 1) ? 16'd0 : counter + 16'd1;
    end
    assign compare_match = (counter < duty);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin pwm_high <= 1'b0; pwm_low <= 1'b0; end
        else begin
            pwm_high <= compare_match & (counter >= deadtime);
            pwm_low <= ~compare_match & (counter >= (period - deadtime) || 
                      counter < (period - duty));
        end
    end
endmodule