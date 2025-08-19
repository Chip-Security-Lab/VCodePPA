//SystemVerilog
//=============================================================================
// 顶层模块
//=============================================================================
module dynamic_endian #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] data_in,
    input              reverse_en,
    output [WIDTH-1:0] data_out
);
    // 连接到位反转子模块的信号
    wire [WIDTH-1:0] reversed_data;
    
    // 位反转子模块实例化
    bit_reverser #(
        .WIDTH(WIDTH)
    ) bit_reverse_unit (
        .data_in (data_in),
        .data_out(reversed_data)
    );
    
    // 输出选择器子模块实例化
    output_selector #(
        .WIDTH(WIDTH)
    ) output_select_unit (
        .data_normal (data_in),
        .data_reversed(reversed_data),
        .select      (reverse_en),
        .data_out    (data_out)
    );
    
endmodule

//=============================================================================
// 位反转子模块
//=============================================================================
module bit_reverser #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 优化的位反转逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_bit_reverse
            assign data_out[i] = data_in[WIDTH-1-i];
        end
    endgenerate
    
endmodule

//=============================================================================
// 输出选择器子模块
//=============================================================================
module output_selector #(
    parameter WIDTH = 32
)(
    input  [WIDTH-1:0] data_normal,
    input  [WIDTH-1:0] data_reversed,
    input              select,
    output [WIDTH-1:0] data_out
);
    // 使用连续赋值而非过程块，提高效率
    assign data_out = select ? data_reversed : data_normal;
    
endmodule