module double_edge_gen (
    input clk_in,
    output reg clk_out
);
reg clk_phase;

always @(posedge clk_in) begin
    clk_phase <= ~clk_phase;
end

always @(negedge clk_in) begin
    clk_out <= clk_phase;
end
endmodule
