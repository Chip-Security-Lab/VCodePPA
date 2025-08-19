module fractional_divider #(
    parameter ACC_WIDTH = 8,
    parameter STEP = 85  // 1.6分频示例值（STEP = 256 * 5/8）
)(
    input clk,
    input rst,
    output reg clk_out
);
reg [ACC_WIDTH-1:0] phase_acc;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        phase_acc <= 0;
        clk_out <= 0;
    end else begin
        phase_acc <= phase_acc + STEP;
        clk_out <= phase_acc[ACC_WIDTH-1];
    end
end
endmodule
