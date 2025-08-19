module clk_gate_div #(parameter DIV=2) (
    input clk, en,
    output reg clk_out
);
reg [7:0] cnt;
always @(posedge clk) begin
    if(en) begin
        cnt <= (cnt == DIV-1) ? 0 : cnt + 1;
        clk_out <= (cnt == 0) ? ~clk_out : clk_out;
    end
end
endmodule