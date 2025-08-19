//SystemVerilog
module pwm_generator(
    input wire clk, reset,
    input wire [7:0] duty_cycle,
    input wire update,
    output reg pwm_out
);

    reg [7:0] counter;
    reg [7:0] duty_reg;
    reg loading;
    
    wire counter_max = &counter;
    wire load_enable = counter_max & update;
    wire pwm_active = counter < duty_reg;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 8'd0;
            duty_reg <= 8'd0;
            loading <= 1'b0;
            pwm_out <= 1'b0;
        end else begin
            counter <= counter + 8'd1;
            loading <= load_enable;
            if (loading) 
                duty_reg <= duty_cycle;
            pwm_out <= pwm_active;
        end
    end

endmodule