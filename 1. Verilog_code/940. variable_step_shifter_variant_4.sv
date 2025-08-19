//SystemVerilog
module variable_step_shifter (
    input [15:0] din,
    input [1:0] step_mode,  // 00:+1, 01:+2, 10:+4
    output reg [15:0] dout
);
    // 使用case语句替代位移计算，避免动态位移和额外的逻辑
    always @(*) begin
        case(step_mode)
            2'b00: dout = {din[14:0], din[15]};    // 左移1位
            2'b01: dout = {din[13:0], din[15:14]}; // 左移2位
            2'b10: dout = {din[11:0], din[15:12]}; // 左移4位
            2'b11: dout = {din[7:0], din[15:8]};   // 左移8位 (扩展功能)
        endcase
    end
endmodule