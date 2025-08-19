module clock_gate (
    input clk,
    input enable,
    output gated_clk
);
reg gate_reg;

always @(*) begin
    if (clk) gate_reg = enable;
end

assign gated_clk = clk & gate_reg;
endmodule
