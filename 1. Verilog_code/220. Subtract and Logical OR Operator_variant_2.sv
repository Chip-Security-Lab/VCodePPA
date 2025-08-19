//SystemVerilog
// 顶层模块
module subtract_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] difference,
    output [7:0] shifted_result
);
    // 实例化减法子模块
    subtractor sub_unit (
        .operand_a(a),
        .operand_b(b),
        .result(difference)
    );
    
    // 实例化移位子模块
    shifter shift_unit (
        .data_in(a),
        .shift_amount(shift_amount),
        .data_out(shifted_result)
    );
endmodule

// 减法子模块 - 使用借位减法器算法实现
module subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // 借位初始化为0
    assign borrow[0] = 1'b0;
    
    // 实现借位减法器
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_sub_loop
            assign diff[i] = operand_a[i] ^ operand_b[i] ^ borrow[i];
            assign borrow[i+1] = (~operand_a[i] & operand_b[i]) | 
                                 (~operand_a[i] & borrow[i]) | 
                                 (operand_b[i] & borrow[i]);
        end
    endgenerate
    
    // 输出差值
    assign result = diff;
endmodule

// 移位子模块
module shifter #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input [DATA_WIDTH-1:0] data_in,
    input [SHIFT_WIDTH-1:0] shift_amount,
    output [DATA_WIDTH-1:0] data_out
);
    // 桶形移位器实现，提高性能
    assign data_out = data_in >> shift_amount;
endmodule