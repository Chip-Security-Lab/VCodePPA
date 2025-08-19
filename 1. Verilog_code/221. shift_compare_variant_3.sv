//SystemVerilog
module shift_compare (
    input [4:0] x,
    input [4:0] y,
    output [4:0] shift_left,
    output [4:0] shift_right,
    output equal
);
    // 优化的移位操作 - 避免使用完整的移位器
    assign shift_left = {x[3:0], 1'b0};
    assign shift_right = {1'b0, y[4:1]};
    
    // 优化的比较操作 - 使用位异或和归约操作
    wire [4:0] xor_result;
    assign xor_result = x ^ y;
    assign equal = ~|xor_result;
endmodule