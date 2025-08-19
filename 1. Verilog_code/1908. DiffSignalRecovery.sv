module DiffSignalRecovery #(parameter THRESHOLD=100) (
    input clk,
    input diff_p, diff_n,
    output reg recovered
);
    wire signed [15:0] diff = diff_p - diff_n;
    always @(posedge clk) begin
        recovered <= (diff > THRESHOLD)  ? 1'b1 :
                    (diff < -THRESHOLD) ? 1'b0 : recovered;
    end
endmodule
