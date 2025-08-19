module TimerSync #(parameter WIDTH=16) (
    input clk, rst_n, enable,
    output reg timer_out
);
reg [WIDTH-1:0] counter;
always @(posedge clk) begin
    if (!rst_n) begin
        counter <= 0;
        timer_out <= 0;
    end else if (enable) begin
        counter <= (counter == {WIDTH{1'b1}}) ? 0 : counter + 1;
        timer_out <= (counter == {WIDTH{1'b1}});
    end
end
endmodule