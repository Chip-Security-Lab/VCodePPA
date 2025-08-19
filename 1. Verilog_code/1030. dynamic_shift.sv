module dynamic_shift #(parameter W=8) (
    input clk,
    input [3:0] ctrl, // [1:0]：方向，[3:2]：类型
    input [W-1:0] din,
    output reg [W-1:0] dout
);
always @(posedge clk) begin
    case({ctrl[3:2], ctrl[1:0]})
        00: dout <= din << 1;     // 逻辑左移
        01: dout <= din >> 1;     // 逻辑右移
        10: dout <= {din[6:0], din[7]};  // 循环左移
        11: dout <= {din[0], din[7:1]};  // 循环右移
    endcase
end
endmodule