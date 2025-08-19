module reset_pulse_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input wire clk,
    input wire reset_in,
    output reg reset_out
);
    reg [2:0] counter;
    always @(posedge clk) begin
        if (reset_in) begin
            counter <= STRETCH_COUNT;
            reset_out <= 1'b1;
        end else if (counter > 0) begin
            counter <= counter - 1'b1;
            reset_out <= 1'b1;
        end else 
            reset_out <= 1'b0;
    end
endmodule
