module counter_sync_inc #(parameter WIDTH=4) (
    input clk, rst_n, en,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (!rst_n) cnt <= 0;
    else if (en) cnt <= cnt + 1;
end
endmodule