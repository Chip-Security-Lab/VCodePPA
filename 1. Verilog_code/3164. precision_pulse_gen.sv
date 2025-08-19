module precision_pulse_gen #(
    parameter CLK_FREQ_HZ = 100000000,
    parameter PULSE_US = 10
)(
    input clk,
    input rst_n,
    input trigger,
    output reg pulse_out
);
    localparam COUNT = (CLK_FREQ_HZ / 1000000) * PULSE_US;
    reg [$clog2(COUNT)-1:0] counter;
    reg active;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            pulse_out <= 0;
            active <= 0;
        end else if (trigger && !active) begin
            active <= 1;
            pulse_out <= 1;
            counter <= 0;
        end else if (active) begin
            if (counter == COUNT-1) begin
                pulse_out <= 0;
                active <= 0;
            end else counter <= counter + 1;
        end
    end
endmodule