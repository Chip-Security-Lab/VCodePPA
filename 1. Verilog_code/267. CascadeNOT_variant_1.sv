//SystemVerilog
//顶层模块
module CascadeNOT(
    input [3:0] bits,
    output [3:0] inv_bits
);
    // 实例化参数化的位反转子模块
    BitInverter #(.WIDTH(4)) inverter_inst (
        .data_in(bits),
        .data_out(inv_bits)
    );
endmodule

// 参数化的位反转子模块
module BitInverter #(
    parameter WIDTH = 4  // 默认宽度为4位，但可配置为其他宽度
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    // 使用生成块来创建可扩展的反转逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : inverter_loop
            // 使用连续赋值代替离散门，提高抽象级别并减少代码量
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule