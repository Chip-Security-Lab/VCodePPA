//SystemVerilog
module one_shot_pulse(
    input clk,
    input trigger,
    output reg pulse
);
    reg [1:0] state;
    parameter IDLE = 2'b00, PULSE = 2'b01, WAIT = 2'b10;
    
    always @(posedge clk) begin
        if (state == IDLE) begin
            if (trigger) begin
                pulse <= 1'b1;
                state <= PULSE;
            end
        end
        else if (state == PULSE) begin
            pulse <= 1'b0;
            state <= WAIT;
        end
        else if (state == WAIT) begin
            if (!trigger)
                state <= IDLE;
        end
        else begin
            state <= IDLE;
        end
    end
endmodule