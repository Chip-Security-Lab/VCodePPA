module dual_channel_shifter (
    input clk,
    input [15:0] ch1, ch2,
    input [3:0] shift,
    output reg [15:0] out1, out2
);
always @(posedge clk) begin
    out1 <= (ch1 << shift) | (ch1 >> (16 - shift));
    out2 <= (ch2 >> shift) | (ch2 << (16 - shift));
end
endmodule