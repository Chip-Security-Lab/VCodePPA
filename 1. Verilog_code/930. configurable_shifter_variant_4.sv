//SystemVerilog
//-----------------------------------------------------------------------------
// Configurable Shifter Top Module - 顶层模块
//-----------------------------------------------------------------------------
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
    // Internal signals for connecting submodules
    wire [WIDTH-1:0] logical_shift_result;
    wire [WIDTH-1:0] rotation_shift_result;
    wire [WIDTH-1:0] arithmetic_shift_result;
    wire [WIDTH-1:0] final_result;
    
    // Module instantiation for logical shift operations
    logical_shifter #(
        .WIDTH(WIDTH)
    ) logical_shift_inst (
        .operand(operand),
        .shift_amount(shift_amount),
        .shift_left(mode[0] == 1'b0), // 0 for left, 1 for right
        .result(logical_shift_result)
    );
    
    // Module instantiation for rotation operations
    rotation_shifter #(
        .WIDTH(WIDTH)
    ) rotation_shift_inst (
        .operand(operand),
        .shift_amount(shift_amount),
        .rotate_left(mode[0] == 1'b0), // 0 for left, 1 for right
        .result(rotation_shift_result)
    );
    
    // Module instantiation for arithmetic shift operations
    arithmetic_shifter #(
        .WIDTH(WIDTH)
    ) arithmetic_shift_inst (
        .operand(operand),
        .shift_amount(shift_amount),
        .result(arithmetic_shift_result)
    );
    
    // Result selector based on operation mode
    result_selector #(
        .WIDTH(WIDTH)
    ) result_sel_inst (
        .logical_result(logical_shift_result),
        .rotation_result(rotation_shift_result),
        .arithmetic_result(arithmetic_shift_result),
        .mode(mode),
        .operand(operand),
        .result(final_result)
    );
    
    // Output assignment
    assign result = final_result;
    
endmodule

//-----------------------------------------------------------------------------
// Logical Shifter Module - 逻辑移位子模块
//-----------------------------------------------------------------------------
module logical_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input shift_left,  // 1 for left shift, 0 for right shift
    output [WIDTH-1:0] result
);
    reg [WIDTH-1:0] shifted_data;
    
    always @(*) begin
        if (shift_left)
            shifted_data = operand << shift_amount;
        else
            shifted_data = operand >> shift_amount;
    end
    
    assign result = shifted_data;
endmodule

//-----------------------------------------------------------------------------
// Rotation Shifter Module - 循环移位子模块
//-----------------------------------------------------------------------------
module rotation_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input rotate_left,  // 1 for left rotation, 0 for right rotation
    output [WIDTH-1:0] result
);
    wire [2*WIDTH-1:0] double_operand;
    reg [WIDTH-1:0] rotated_data;
    
    // Double operand for rotation operations
    assign double_operand = {operand, operand};
    
    always @(*) begin
        if (rotate_left)
            rotated_data = double_operand >> (WIDTH - shift_amount);
        else
            rotated_data = double_operand >> shift_amount;
    end
    
    assign result = rotated_data;
endmodule

//-----------------------------------------------------------------------------
// Arithmetic Shifter Module - 算术移位子模块
//-----------------------------------------------------------------------------
module arithmetic_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    output [WIDTH-1:0] result
);
    reg [WIDTH-1:0] shifted_data;
    
    always @(*) begin
        shifted_data = $signed(operand) >>> shift_amount;
    end
    
    assign result = shifted_data;
endmodule

//-----------------------------------------------------------------------------
// Result Selector Module - 结果选择子模块
//-----------------------------------------------------------------------------
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
            3'b000, 3'b001: selected_result = logical_result;    // Logical shifts
            3'b010, 3'b011: selected_result = rotation_result;   // Rotation shifts
            3'b100:         selected_result = arithmetic_result; // Arithmetic right shift
            default:        selected_result = operand;           // No shift
        endcase
    end
    
    assign result = selected_result;
endmodule