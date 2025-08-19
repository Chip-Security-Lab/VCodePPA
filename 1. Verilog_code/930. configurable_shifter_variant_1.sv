//SystemVerilog
// 顶层模块
module configurable_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input [2:0] mode, // 000:left logical, 001:right logical
                      // 010:left rot, 011:right rot
                      // 100:arithmetic right, others:reserved
    output [WIDTH-1:0] result
);
    // 内部连线
    wire [WIDTH-1:0] logical_shift_result;
    wire [WIDTH-1:0] rotation_shift_result;
    wire [WIDTH-1:0] arithmetic_shift_result;
    wire [2*WIDTH-1:0] double_operand;
    
    // 双倍操作数生成，用于旋转操作
    operand_doubler #(
        .WIDTH(WIDTH)
    ) doubler_inst (
        .operand(operand),
        .double_operand(double_operand)
    );
    
    // 逻辑移位模块
    logical_shifter #(
        .WIDTH(WIDTH)
    ) logical_shift_inst (
        .operand(operand),
        .shift_amount(shift_amount),
        .shift_left(mode[0] == 1'b0),  // mode[0]=0时为左移
        .result(logical_shift_result)
    );
    
    // 旋转移位模块
    rotation_shifter #(
        .WIDTH(WIDTH)
    ) rotation_shift_inst (
        .double_operand(double_operand),
        .shift_amount(shift_amount),
        .shift_left(mode[0] == 1'b0),  // mode[0]=0时为左旋转
        .width(WIDTH),
        .result(rotation_shift_result)
    );
    
    // 算术右移模块
    arithmetic_shifter #(
        .WIDTH(WIDTH)
    ) arithmetic_shift_inst (
        .operand(operand),
        .shift_amount(shift_amount),
        .result(arithmetic_shift_result)
    );
    
    // 移位结果选择器
    result_selector #(
        .WIDTH(WIDTH)
    ) selector_inst (
        .logical_result(logical_shift_result),
        .rotation_result(rotation_shift_result),
        .arithmetic_result(arithmetic_shift_result),
        .operand(operand),
        .mode(mode),
        .result(result)
    );
endmodule

// 操作数加倍器模块
module operand_doubler #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    output [2*WIDTH-1:0] double_operand
);
    assign double_operand = {operand, operand};
endmodule

// 逻辑移位模块
module logical_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input shift_left,  // 1为左移，0为右移
    output [WIDTH-1:0] result
);
    assign result = shift_left ? 
                   (operand << shift_amount) : 
                   (operand >> shift_amount);
endmodule

// 旋转移位模块
module rotation_shifter #(
    parameter WIDTH = 24
)(
    input [2*WIDTH-1:0] double_operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input shift_left,  // 1为左旋转，0为右旋转
    input [WIDTH-1:0] width,
    output [WIDTH-1:0] result
);
    reg [WIDTH-1:0] shifted_result;
    
    always @(*) begin
        if (shift_left)
            shifted_result = double_operand >> (width - shift_amount);
        else
            shifted_result = double_operand >> shift_amount;
    end
    
    assign result = shifted_result;
endmodule

// 算术右移模块
module arithmetic_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    output [WIDTH-1:0] result
);
    assign result = $signed(operand) >>> shift_amount;
endmodule

// 结果选择器模块
module result_selector #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] logical_result,
    input [WIDTH-1:0] rotation_result,
    input [WIDTH-1:0] arithmetic_result,
    input [WIDTH-1:0] operand,
    input [2:0] mode,
    output [WIDTH-1:0] result
);
    reg [WIDTH-1:0] selected_result;
    
    always @(*) begin
        case(mode)
            3'b000, 3'b001: selected_result = logical_result;   // 逻辑移位
            3'b010, 3'b011: selected_result = rotation_result;  // 旋转移位
            3'b100:         selected_result = arithmetic_result; // 算术右移
            default:        selected_result = operand;          // 无移位
        endcase
    end
    
    assign result = selected_result;
endmodule