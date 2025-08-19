module arithmetic_logic_unit (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: and, 11: or
    output reg [7:0] result
);
    always @(*) begin
        case (op_select)
            2'b00: result = a + b;  // 加法
            2'b01: result = a - b;  // 减法
            2'b10: result = a & b;  // 与操作
            2'b11: result = a | b;  // 或操作
            default: result = 8'b0;
        endcase
    end
endmodule
