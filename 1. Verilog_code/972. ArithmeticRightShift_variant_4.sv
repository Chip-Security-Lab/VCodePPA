//SystemVerilog
// 顶层模块
module ArithmeticRightShift #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire shift_amount,
    output wire [WIDTH-1:0] data_out
);
    // 内部连线
    wire sign_bit;
    wire [WIDTH-1:0] shifted_data;
    
    // 提取符号位
    assign sign_bit = data_in[WIDTH-1];
    
    // 条件反相减法器实现算术右移
    wire [WIDTH-1:0] minuend;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] inverted_subtrahend;
    wire carry_in;
    wire [WIDTH-1:0] sub_result;
    
    // 只在需要移位时执行减法操作
    assign minuend = data_in;
    assign subtrahend = shift_amount ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};
    assign inverted_subtrahend = ~subtrahend;
    assign carry_in = 1'b1; // 减法时的进位
    
    // 使用条件反相减法器算法
    assign sub_result = minuend + inverted_subtrahend + carry_in;
    
    // 如果是算术右移，需要保持符号位
    assign shifted_data = shift_amount ? 
                         {sign_bit, sub_result[WIDTH-1:1]} : 
                         data_in;
    
    // 形成最终输出
    assign data_out = shifted_data;
    
endmodule