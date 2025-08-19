module pwm_div #(parameter HIGH=3, LOW=5) (
    input clk, rst_n,
    output reg out
);
reg [7:0] cnt;
always @(posedge clk) begin
    if(!rst_n) begin
        cnt <= 0;
        out <= 0;
    end else begin
        cnt <= (cnt == HIGH+LOW-1) ? 0 : cnt + 1;
        out <= (cnt < HIGH);
    end
end
endmodule
