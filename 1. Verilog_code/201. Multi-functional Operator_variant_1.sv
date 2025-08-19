//SystemVerilog
module multi_function_operator (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: multiply, 11: divide
    output reg [15:0] result,
    output reg valid
);
    // 预先计算除法安全性检查
    wire b_zero = (b == 8'b0);
    
    // 提前计算各种操作的结果
    wire [15:0] add_result = {8'b0, a} + {8'b0, b};
    wire [15:0] sub_result = {8'b0, a} - {8'b0, b};
    wire [15:0] mul_result = a * b;
    wire [15:0] div_result = b_zero ? 16'b0 : {8'b0, a} / {8'b0, b};
    
    // 使用优化的选择逻辑
    always @(*) begin
        valid = 1'b1;  // 默认有效
        
        case (op_select)
            2'b00: result = add_result;
            2'b01: result = sub_result;
            2'b10: result = mul_result;
            2'b11: begin
                result = div_result;
                valid = ~b_zero;  // 除数为零时结果无效
            end
            default: begin
                result = 16'b0;
                valid = 1'b0;
            end
        endcase
    end
endmodule