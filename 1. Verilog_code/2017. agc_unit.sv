module agc_unit #(W=16)(input clk, input [W-1:0] in, output reg [W-1:0] out);
reg [W+1:0] peak=0; always @(posedge clk) begin
    peak <= (in > peak) ? in : peak - (peak>>3);
    out <= (in * 32767) / (peak ? peak : 1);
end
endmodule