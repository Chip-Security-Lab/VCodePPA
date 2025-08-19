module async_load_dff (
    input clk, load,
    input [3:0] data,
    output reg [3:0] q
);
always @(posedge clk or posedge load) begin
    if (load)    q <= data;
    else if (clk) q <= q + 1;
end
endmodule