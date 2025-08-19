//SystemVerilog
// Counter module
module pwm_counter(
    input clk,
    input rst,
    output reg [7:0] count
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 8'd0;
        else
            count <= count + 8'd1;
    end
endmodule

// PWM generation module
module pwm_generator(
    input [7:0] count,
    input [7:0] duty,
    input [3:0] dead_time,
    output reg pwm_high,
    output reg pwm_low
);
    wire [7:0] dead_time_ext = {4'd0, dead_time};
    
    always @(*) begin
        pwm_high = (count < duty);
        pwm_low = (count > duty + dead_time_ext);
    end
endmodule

// Top level module
module pwm_dead_time(
    input clk,
    input rst,
    input [7:0] duty,
    input [3:0] dead_time,
    output pwm_high,
    output pwm_low
);
    wire [7:0] counter;
    
    pwm_counter counter_inst(
        .clk(clk),
        .rst(rst),
        .count(counter)
    );
    
    pwm_generator pwm_gen_inst(
        .count(counter),
        .duty(duty),
        .dead_time(dead_time),
        .pwm_high(pwm_high),
        .pwm_low(pwm_low)
    );
endmodule