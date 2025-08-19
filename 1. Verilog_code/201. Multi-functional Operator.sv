module multi_function_operator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: multiply, 11: divide
    output reg [15:0] result,
    output reg valid
);
    always @(*) begin
        case (op_select)
            2'b00: result = a + b;  // 加法
            2'b01: result = a - b;  // 减法
            2'b10: result = a * b;  // 乘法
            2'b11: begin
                if (b != 0)
                    result = a / b;  // 除法
                else
                    result = 16'b0;  // 除以0
            end
            default: result = 16'b0;
        endcase
        valid = 1;
    end
endmodule
