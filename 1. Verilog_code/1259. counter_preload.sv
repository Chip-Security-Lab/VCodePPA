module counter_preload #(parameter WIDTH=4) (
    input clk, load, en,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (load) cnt <= data;
    else if (en) cnt <= cnt + 1;
end
endmodule