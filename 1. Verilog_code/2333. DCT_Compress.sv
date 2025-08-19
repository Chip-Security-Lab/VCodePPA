module DCT_Compress (
    input clk, en,
    input [7:0] data_in,
    output reg [7:0] data_out
);
reg signed [15:0] sum = 0;
always @(posedge clk) if(en) begin
    sum <= data_in * 8'd23170;  // cos(π/4) * 32768
    data_out <= (sum >>> 15) + 128;
end
endmodule
