module counter_shift_load #(parameter WIDTH=4) (
    input clk, load, shift,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
always @(posedge clk) begin
    if (load) cnt <= data;
    else if (shift) cnt <= {cnt[WIDTH-2:0], cnt[WIDTH-1]};
end
endmodule