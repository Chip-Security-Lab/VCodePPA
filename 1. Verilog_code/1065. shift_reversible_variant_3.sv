//SystemVerilog
module shift_reversible #(parameter WIDTH=8) (
    input wire clk,
    input wire reverse,
    input wire [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

wire [WIDTH-1:0] shift_left_comb;
wire [WIDTH-1:0] shift_right_comb;
wire [WIDTH-1:0] shift_result_comb;

// 组合逻辑：左移和右移操作
assign shift_left_comb  = {din[WIDTH-2:0], din[WIDTH-1]};
assign shift_right_comb = {din[0], din[WIDTH-1:1]};

// 组合逻辑：根据reverse信号选择移位方向
assign shift_result_comb = reverse ? shift_right_comb : shift_left_comb;

// 时序逻辑：寄存移位结果
always @(posedge clk) begin
    dout <= shift_result_comb;
end

endmodule