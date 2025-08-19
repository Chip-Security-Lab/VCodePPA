module random_pulse #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B
)(
    input clk,
    input rst,
    output reg pulse
);
reg [LFSR_WIDTH-1:0] lfsr;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        lfsr <= SEED;
        pulse <= 0;
    end else begin
        lfsr <= {lfsr[LFSR_WIDTH-2:0], lfsr[7] ^ lfsr[3] ^ lfsr[2] ^ lfsr[0]};
        pulse <= (lfsr < 8'h20);  // 调节生成概率
    end
end
endmodule
