module WaveletFilter #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] approx, detail
);
    reg [W-1:0] prev_sample;
    always @(posedge clk) begin
        approx <= (din + prev_sample) >> 1;
        detail <= din - prev_sample;
        prev_sample <= din;
    end
endmodule