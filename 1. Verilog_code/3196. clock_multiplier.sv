module clock_multiplier #(
    parameter MULT_RATIO = 4
)(
    input clk_ref,
    output reg clk_out
);
reg [1:0] phase_counter;

always @(negedge clk_ref) begin
    phase_counter <= phase_counter + 1;
    clk_out <= phase_counter[1];
end
endmodule
