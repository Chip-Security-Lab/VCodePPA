//SystemVerilog
// 顶层模块
module bin2thermometer #(
    parameter BIN_WIDTH = 3
) (
    input      [BIN_WIDTH-1:0] bin_input,
    output     [(2**BIN_WIDTH)-2:0] therm_output
);
    // 比较单元内部总线
    wire [BIN_WIDTH-1:0] bin_value;
    
    // 输入缓冲子模块实例化
    input_buffer #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_input_buffer (
        .bin_in(bin_input),
        .bin_out(bin_value)
    );
    
    // 温度计编码生成器子模块实例化
    thermometer_encoder #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_thermometer_encoder (
        .bin_data(bin_value),
        .therm_data(therm_output)
    );
    
endmodule

// 输入缓冲子模块 - 增强驱动能力并隔离输入
module input_buffer #(
    parameter BIN_WIDTH = 3
) (
    input  [BIN_WIDTH-1:0] bin_in,
    output [BIN_WIDTH-1:0] bin_out
);
    // 简单缓冲，也可以在此添加输入寄存
    assign bin_out = bin_in;
endmodule

// 温度计编码生成器子模块
module thermometer_encoder #(
    parameter BIN_WIDTH = 3
) (
    input  [BIN_WIDTH-1:0] bin_data,
    output [(2**BIN_WIDTH)-2:0] therm_data
);
    // 内部比较结果存储
    reg [(2**BIN_WIDTH)-2:0] encoder_result;
    
    // 并行比较实现温度计编码生成
    genvar i;
    generate
        for (i = 0; i < (2**BIN_WIDTH)-1; i = i + 1) begin : comp_gen
            // 对每一位进行单独的比较逻辑
            comparison_unit #(
                .BIN_WIDTH(BIN_WIDTH),
                .INDEX(i)
            ) u_comp_unit (
                .bin_value(bin_data),
                .therm_bit(therm_data[i])
            );
        end
    endgenerate
endmodule

// 单比较单元子模块 - 为每个输出位实现并行比较
module comparison_unit #(
    parameter BIN_WIDTH = 3,
    parameter INDEX = 0
) (
    input  [BIN_WIDTH-1:0] bin_value,
    output therm_bit
);
    // 对当前索引与输入值进行比较
    assign therm_bit = (INDEX < bin_value) ? 1'b1 : 1'b0;
endmodule