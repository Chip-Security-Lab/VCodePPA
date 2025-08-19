//SystemVerilog
module duty_cycle_timer #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period,
    input [7:0] duty_percent, // 0-100%
    output reg pwm_out
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] duty_ticks_reg;
    wire counter_reset;
    wire [WIDTH+7:0] duty_product; // Pre-computed product before division
    
    // Pre-compute product to reduce logic depth
    assign duty_product = period * duty_percent;
    
    // Simplify counter reset condition
    assign counter_reset = (counter >= period - 1'b1);
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            duty_ticks_reg <= {WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            // Register duty_ticks calculation to break long combinational path
            duty_ticks_reg <= duty_product / 8'd100;
            
            // Counter logic
            if (counter_reset) begin
                counter <= {WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            // PWM output logic
            pwm_out <= (counter < duty_ticks_reg);
        end
    end
endmodule