//SystemVerilog
module adaptive_pwm #(
    parameter WIDTH = 8
)(
    input clk,
    input feedback,
    output reg pwm
);
reg [WIDTH-1:0] duty_cycle;
reg [WIDTH-1:0] counter;
reg [WIDTH-1:0] sub_result;
reg borrow;

always @(posedge clk) begin
    counter <= counter + 1;
    pwm <= (counter < duty_cycle);
    
    // 条件反相减法器算法实现
    if (feedback && duty_cycle < 8'hFF) begin
        duty_cycle <= duty_cycle + 1;
    end
    else if (!feedback && duty_cycle > 8'h00) begin
        // 条件反相减法器算法
        {borrow, sub_result} <= {1'b0, duty_cycle} + {1'b0, ~8'h01} + 1'b1;
        duty_cycle <= sub_result;
    end
end
endmodule