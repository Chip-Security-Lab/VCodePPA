module PrescalerTimer #(parameter PRESCALE=8) (
    input clk, rst_n,
    output reg tick
);
reg [$clog2(PRESCALE)-1:0] ps_cnt;
always @(posedge clk) begin
    if (!rst_n) begin
        ps_cnt <= 0;
        tick <= 0;
    end else begin
        ps_cnt <= (ps_cnt == PRESCALE-1) ? 0 : ps_cnt + 1;
        tick <= (ps_cnt == PRESCALE-1);
    end
end
endmodule