//SystemVerilog
module param_logical_shift #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input signed [WIDTH-1:0] din,
    input [SHIFT_W-1:0] shift,
    output signed [WIDTH-1:0] dout
);
    reg signed [WIDTH-1:0] result;
    reg [WIDTH-1:0] abs_din;
    reg sign_bit;
    reg [WIDTH-1:0] shifted_abs;
    
    always @(*) begin
        // 获取输入的符号位和绝对值
        sign_bit = din[WIDTH-1];
        abs_din = sign_bit ? (~din + 1'b1) : din;
        
        // 进行逻辑左移
        shifted_abs = abs_din << shift;
        
        // 根据原始符号位恢复结果
        result = sign_bit ? (~shifted_abs + 1'b1) : shifted_abs;
    end
    
    assign dout = result;
endmodule