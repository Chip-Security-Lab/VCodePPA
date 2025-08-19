//SystemVerilog
module multi_function_operator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: multiply, 11: divide
    output reg [15:0] result,
    output reg valid
);
    // 内部信号声明
    reg [15:0] temp_result;
    reg div_valid;

    // 运算处理
    always @(*) begin
        valid = 1'b1;  // 默认有效
        div_valid = (b != 0);  // 除零检查

        case (op_select)
            2'b00: temp_result = a + b;  // 加法
            2'b01: temp_result = a - b;  // 减法
            2'b10: temp_result = a * b;  // 乘法
            2'b11: temp_result = div_valid ? (a / b) : 16'b0;  // 除法
            default: begin
                temp_result = 16'b0;
                valid = 1'b0;
            end
        endcase

        // 输出最终结果
        result = temp_result;
        if (op_select == 2'b11) begin
            valid = div_valid;  // 更新有效标志
        end
    end
endmodule