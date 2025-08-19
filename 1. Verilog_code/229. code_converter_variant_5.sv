//SystemVerilog
// 顶层模块，协调二进制到格雷码和独热码的转换
module code_converter (
    input [2:0] binary,
    output [2:0] gray,
    output [7:0] one_hot
);
    // 实例化格雷码转换子模块
    binary_to_gray b2g_inst (
        .binary_in(binary),
        .gray_out(gray)
    );
    
    // 实例化独热码转换子模块
    binary_to_onehot b2o_inst (
        .binary_in(binary),
        .onehot_out(one_hot)
    );
endmodule

// 二进制到格雷码转换子模块
module binary_to_gray #(
    parameter WIDTH = 3
)(
    input [WIDTH-1:0] binary_in,
    output [WIDTH-1:0] gray_out
);
    // 格雷码转换逻辑
    assign gray_out = binary_in ^ (binary_in >> 1);
endmodule

// 二进制到独热码转换子模块
module binary_to_onehot #(
    parameter WIDTH = 3,
    parameter OUT_WIDTH = (1 << WIDTH)
)(
    input [WIDTH-1:0] binary_in,
    output [OUT_WIDTH-1:0] onehot_out
);
    // 独热码转换逻辑
    assign onehot_out = {{(OUT_WIDTH-1){1'b0}}, 1'b1} << binary_in;
endmodule