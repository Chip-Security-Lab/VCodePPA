module variable_step_counter #(parameter STEP=1) (
    input clk, rst,
    output reg [7:0] ring_reg
);
always @(posedge clk) begin
    if (rst) ring_reg <= 8'h01;
    else ring_reg <= {ring_reg[STEP-1:0], ring_reg[7:STEP]};
end
endmodule
