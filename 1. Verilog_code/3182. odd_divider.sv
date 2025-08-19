module odd_divider #(
    parameter N = 5
)(
    input clk,
    input rst,
    output clk_out
);
reg [2:0] state;
wire phase_clk;

always @(posedge clk or posedge rst) begin
    if (rst) state <= 0;
    else if (state == N-1) state <= 0;
    else state <= state + 1;
end

assign phase_clk = (state < (N>>1)) ? 1 : 0;

reg phase_clk_neg;
always @(negedge clk) begin
    phase_clk_neg <= phase_clk;
end

assign clk_out = phase_clk | phase_clk_neg;
endmodule
