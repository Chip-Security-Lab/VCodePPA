//SystemVerilog
// 顶层模块
module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);
    // 内部信号定义
    wire [2:0] gray_temp;
    wire [7:0] one_hot_temp;
    
    // 实例化二进制到格雷码转换子模块
    binary_to_gray #(
        .WIDTH(3)
    ) bin2gray_inst (
        .binary_in(binary),
        .gray_out(gray_temp)
    );
    
    // 实例化二进制到独热码转换子模块
    binary_to_onehot #(
        .BIN_WIDTH(3),
        .HOT_WIDTH(8)
    ) bin2onehot_inst (
        .binary_in(binary),
        .onehot_out(one_hot_temp)
    );
    
    // 输出赋值
    assign gray = gray_temp;
    assign one_hot = one_hot_temp;
endmodule

// 二进制到格雷码转换子模块
module binary_to_gray #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] binary_in,
    output [WIDTH-1:0] gray_out
);
    // 使用XOR操作实现二进制到格雷码的转换
    // 格雷码的每一位是原二进制的当前位与高一位的异或
    assign gray_out = binary_in ^ (binary_in >> 1);
endmodule

// 二进制到独热码转换子模块
module binary_to_onehot #(
    parameter BIN_WIDTH = 3,
    parameter HOT_WIDTH = 8
)(
    input [BIN_WIDTH-1:0] binary_in,
    output [HOT_WIDTH-1:0] onehot_out
);
    // 通过移位操作实现二进制到独热码的转换
    // 独热码是将'1'左移二进制值的位数
    assign onehot_out = {{(HOT_WIDTH-1){1'b0}}, 1'b1} << binary_in;
endmodule