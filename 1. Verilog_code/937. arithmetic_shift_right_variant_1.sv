//SystemVerilog
// 顶层模块
module arithmetic_shift_right (
    input wire signed [31:0] data_in,
    input wire [4:0] shift,
    output wire signed [31:0] data_out
);
    // 控制逻辑和数据路径分离
    wire shift_enable;
    wire [4:0] shift_amount;
    wire signed [31:0] shift_data;
    
    // 实例化控制子模块
    shift_controller controller (
        .shift_in(shift),
        .shift_enable(shift_enable),
        .shift_amount(shift_amount)
    );
    
    // 实例化数据处理子模块
    shift_datapath datapath (
        .data_in(data_in),
        .shift_enable(shift_enable),
        .shift_amount(shift_amount),
        .shift_data(shift_data)
    );
    
    // 实例化输出处理子模块
    output_handler output_stage (
        .shift_data(shift_data),
        .data_out(data_out)
    );
    
endmodule

// 控制器子模块 - 处理移位使能和移位量验证
module shift_controller (
    input wire [4:0] shift_in,
    output wire shift_enable,
    output wire [4:0] shift_amount
);
    // 当移位量非零时启用移位操作
    assign shift_enable = |shift_in;
    // 将移位量传递给数据路径
    assign shift_amount = shift_in;
    
endmodule

// 数据路径子模块 - 执行实际的移位运算
module shift_datapath (
    input wire signed [31:0] data_in,
    input wire shift_enable,
    input wire [4:0] shift_amount,
    output wire signed [31:0] shift_data
);
    // 根据移位使能决定是否执行移位
    assign shift_data = shift_enable ? (data_in >>> shift_amount) : data_in;
    
endmodule

// 输出处理子模块 - 确保输出数据符合要求
module output_handler (
    input wire signed [31:0] shift_data,
    output wire signed [31:0] data_out
);
    // 将处理后的数据传递到输出
    assign data_out = shift_data;
    
endmodule