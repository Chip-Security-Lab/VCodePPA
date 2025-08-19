module dyn_mode_shifter (
    input [15:0] data,
    input [3:0] shift,
    input [1:0] mode, // 00-逻辑左 01-算术右 10-循环
    output reg [15:0] res
);
always @* begin
    case(mode)
        2'b00: res = data << shift;
        2'b01: res = $signed(data) >>> shift;
        2'b10: res = (data << shift) | (data >> (16 - shift));
        default: res = data;
    endcase
end
endmodule