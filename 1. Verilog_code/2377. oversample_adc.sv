module oversample_adc (
    input clk, adc_in,
    output reg [7:0] adc_out
);
reg [2:0] sum;
always @(posedge clk) begin
    sum <= sum + adc_in;
    if (&sum[2:0]) adc_out <= sum[2:0] << 5;
end
endmodule
