module counter_pause #(parameter WIDTH=4) (
    input clk, rst, pause,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (rst) cnt <= 0;
    else if (!pause) cnt <= cnt + 1;
end
endmodule