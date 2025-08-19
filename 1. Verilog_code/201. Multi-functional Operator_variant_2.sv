//SystemVerilog
module multi_function_operator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: multiply, 11: divide
    output reg [15:0] result,
    output reg valid
);
    // 提前计算除法是否有效
    wire div_valid = |b;  // 使用归约操作符，当b不为0时为1
    
    // 预计算各种运算结果
    wire [15:0] add_result = {8'b0, a} + {8'b0, b};
    wire [15:0] sub_result = {8'b0, a} - {8'b0, b};
    wire [15:0] mul_result = a * b;
    wire [15:0] div_result = div_valid ? {8'b0, a / b} : 16'b0;
    
    always @(*) begin
        valid = 1'b1;
        
        // 使用三目运算符优化case结构，减少比较链
        case (op_select)
            2'b00: result = add_result;
            2'b01: result = sub_result;
            2'b10: result = mul_result;
            2'b11: result = div_result;
            default: result = 16'b0;
        endcase
    end
endmodule