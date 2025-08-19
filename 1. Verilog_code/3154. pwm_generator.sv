module pwm_generator(
    input clk,
    input rst,
    input [7:0] duty_cycle,
    output reg pwm_out
);
    reg [7:0] counter;
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= 8'h00;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            pwm_out <= (counter < duty_cycle) ? 1'b1 : 1'b0;
        end
    end
endmodule