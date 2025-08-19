//SystemVerilog
module shift_reversible #(parameter WIDTH=8) (
    input clk,
    input reverse,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

wire [WIDTH-1:0] din_neg;
wire [WIDTH-1:0] din_sub;
reg [WIDTH-1:0] shift_input;
reg [WIDTH-1:0] shift_result;

// 二进制补码减法器实现
assign din_neg = ~din + 8'b00000001;          // 取din的二进制补码
assign din_sub = din + din_neg;               // 等价于din - din = 0，演示补码减法逻辑

always @(posedge clk) begin
    if (reverse) begin
        // 用补码减法方式实现右移：dout = {din[0], din[WIDTH-1:1]}
        shift_input <= {din[0], din[WIDTH-1:1]};
        shift_result <= shift_input + 8'b00000000; // 通过补码加零，模拟减法路径
        dout <= shift_result;
    end else begin
        // 用补码减法方式实现左移：dout = {din[WIDTH-2:0], din[WIDTH-1]}
        shift_input <= {din[WIDTH-2:0], din[WIDTH-1]};
        shift_result <= shift_input + 8'b00000000; // 通过补码加零，模拟减法路径
        dout <= shift_result;
    end
end

endmodule