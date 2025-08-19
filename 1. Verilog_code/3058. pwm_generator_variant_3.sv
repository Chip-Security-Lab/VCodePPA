//SystemVerilog
module pwm_generator(
    input wire clk,
    input wire reset,
    input wire [7:0] duty_cycle,
    input wire update,
    output reg pwm_out
);
    reg [7:0] counter;
    reg [7:0] duty_reg;
    reg loading;
    
    // Counter control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
        end
    end
    
    // Duty cycle register update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            duty_reg <= 8'd0;
        end else if (loading) begin
            duty_reg <= duty_cycle;
        end
    end
    
    // Loading control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            loading <= 1'b0;
        end else begin
            loading <= (counter == 8'd255) & update;
        end
    end
    
    // PWM output generation
    always @(*) begin
        pwm_out = (counter < duty_reg);
    end
endmodule