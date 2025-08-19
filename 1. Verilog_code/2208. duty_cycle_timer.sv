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
    wire [WIDTH-1:0] duty_ticks;
    
    // Convert percent to ticks
    assign duty_ticks = (period * duty_percent) / 8'd100;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            if (counter >= period - 1) begin
                counter <= {WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            if (counter < duty_ticks) begin
                pwm_out <= 1'b1;
            end else begin
                pwm_out <= 1'b0;
            end
        end
    end
endmodule