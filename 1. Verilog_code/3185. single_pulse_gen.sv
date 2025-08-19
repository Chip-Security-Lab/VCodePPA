module single_pulse_gen #(
    parameter DELAY_CYCLES = 50
)(
    input clk,
    input trigger,
    output reg pulse
);
reg [31:0] counter;
reg state;

always @(posedge clk) begin
    case(state)
        0: begin
            if (trigger) begin
                counter <= DELAY_CYCLES;
                state <= 1;
            end
        end
        1: begin
            if (counter > 0) begin
                counter <= counter - 1;
                pulse <= (counter == 1);
                state <= (counter == 1) ? 0 : 1;
            end
        end
    endcase
end
endmodule
