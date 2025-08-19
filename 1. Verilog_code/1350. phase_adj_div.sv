module phase_adj_div #(parameter PHASE_STEP=2) (
    input clk, rst, adj_up,
    output reg clk_out
);
reg [7:0] phase;
reg [7:0] cnt;
always @(posedge clk) begin
    if(rst) begin
        cnt <= 0;
        phase <= 0;
        clk_out <= 0;
    end else begin
        phase <= adj_up ? phase + PHASE_STEP : phase - PHASE_STEP;
        cnt <= (cnt == 200 - phase) ? 0 : cnt + 1;
        clk_out <= (cnt < 100 - phase/2);
    end
end
endmodule
