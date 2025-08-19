module PredictCompress (
    input clk, en,
    input [15:0] current,
    output reg [7:0] delta
);
reg [15:0] prev;
always @(posedge clk) if(en) begin
    delta <= current - prev;
    prev <= current;
end
endmodule
