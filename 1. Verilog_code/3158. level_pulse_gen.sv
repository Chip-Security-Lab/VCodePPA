module level_pulse_gen(
    input clock,
    input trigger,
    input [3:0] pulse_width,
    output reg pulse
);
    reg [3:0] counter;
    reg triggered;
    
    always @(posedge clock) begin
        if (trigger && !triggered) begin
            triggered <= 1'b1;
            counter <= 4'd0;
            pulse <= 1'b1;
        end else if (triggered) begin
            if (counter == pulse_width - 1) begin
                pulse <= 1'b0;
                triggered <= 1'b0;
            end else
                counter <= counter + 1'b1;
        end
    end
endmodule