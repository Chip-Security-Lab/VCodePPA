//SystemVerilog
// 顶层模块 - 将1的补码转换为2的补码
module xor_2s_complement(
    input [3:0] data_in,
    output [3:0] xor_out
);
    // 内部连线
    wire [3:0] validated_data;    // 经过验证的数据
    wire [3:0] inverted_data;     // 取反后的数据
    
    // 常量参数定义移至相应子模块
    
    // 实例化数据验证子模块
    data_validator validator_inst (
        .raw_data(data_in),
        .valid_data(validated_data)
    );
    
    // 实例化位反转子模块
    bit_inverter inverter_inst (
        .data_in(validated_data),
        .inverted_out(inverted_data)
    );
    
    // 实例化输出处理子模块
    output_formatter formatter_inst (
        .inverted_data(inverted_data),
        .formatted_result(xor_out)
    );
    
endmodule

// 数据验证子模块 - 确保输入数据符合要求
module data_validator(
    input [3:0] raw_data,
    output [3:0] valid_data
);
    // 当前设计中仅传递数据，但为未来扩展预留接口
    // 可以添加数据范围检查、奇偶校验等功能
    assign valid_data = raw_data;
endmodule

// 位反转子模块 - 执行位翻转操作（1的补码）
module bit_inverter(
    input [3:0] data_in,
    output [3:0] inverted_out
);
    // 常量定义
    localparam INVERT_MASK = 4'b1111;
    
    // 执行位翻转运算
    assign inverted_out = data_in ^ INVERT_MASK;
endmodule

// 输出格式化子模块 - 处理最终输出
module output_formatter(
    input [3:0] inverted_data,
    output [3:0] formatted_result
);
    // 当前设计中直接传递数据，但为未来扩展预留接口
    // 可以添加输出缓冲、状态指示等功能
    assign formatted_result = inverted_data;
endmodule