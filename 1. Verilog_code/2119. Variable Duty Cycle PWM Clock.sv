module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output reg clk_out
);
    reg [$clog2(PERIOD)-1:0] counter;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= (counter < PERIOD-1) ? counter + 1 : 0;
            clk_out <= (counter < duty) ? 1'b1 : 1'b0;
        end
    end
endmodule