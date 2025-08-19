module Pipeline_AND(
    input clk,
    input [15:0] din_a, din_b,
    output reg [15:0] dout
);
    always @(posedge clk) begin
        dout <= din_a & din_b; // 单级流水线
    end
endmodule
