module counter_step #(parameter WIDTH=4, STEP=2) (
    input clk, rst_n,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (!rst_n) cnt <= 0;
    else cnt <= cnt + STEP;
end
endmodule