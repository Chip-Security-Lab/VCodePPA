//SystemVerilog
module pwm_timer (
    input clk, rst, enable,
    input [15:0] period, duty,
    output reg pwm_out
);
    reg [15:0] counter;
    reg [15:0] period_reg, duty_reg;
    reg enable_reg;
    
    // Register inputs first to reduce input-to-register delay
    always @(posedge clk) begin
        if (rst) begin
            period_reg <= 16'd0;
            duty_reg <= 16'd0;
            enable_reg <= 1'b0;
        end
        else begin
            period_reg <= period;
            duty_reg <= duty;
            enable_reg <= enable;
        end
    end
    
    // Counter logic using registered inputs
    always @(posedge clk) begin
        if (rst) begin
            counter <= 16'd0;
            pwm_out <= 1'b0;
        end
        else if (enable_reg) begin
            if (counter >= period_reg - 16'd1) 
                counter <= 16'd0;
            else 
                counter <= counter + 16'd1;
                
            pwm_out <= (counter < duty_reg);
        end
    end
endmodule