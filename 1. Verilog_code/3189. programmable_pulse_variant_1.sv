//SystemVerilog
module programmable_pulse #(
    parameter WIDTH = 16
)(
    input clk,
    input [WIDTH-1:0] period,
    input [WIDTH-1:0] pulse_width,
    output reg pulse
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] period_minus_one;
    reg [WIDTH-1:0] pulse_width_reg;
    
    // Combined always block for all sequential logic with same clock
    always @(posedge clk) begin
        // Period calculation
        period_minus_one <= period - 1'b1;
        
        // Counter logic
        if (counter < period_minus_one)
            counter <= counter + 1'b1;
        else
            counter <= 0;
            
        // Pulse width logic
        pulse_width_reg <= pulse_width;
        
        // Pulse output logic
        pulse <= (counter < pulse_width_reg);
    end
endmodule