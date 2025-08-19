//SystemVerilog
module pwm_gen(
    input clk,
    input reset,
    input [7:0] duty,
    output reg pwm_out
);
    reg [7:0] counter;
    reg [7:0] duty_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= 8'h00;
            duty_reg <= 8'h00;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 1'b1;
            duty_reg <= duty;
            pwm_out <= (counter < duty_reg) ? 1'b1 : 1'b0;
        end
    end
endmodule