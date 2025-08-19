//SystemVerilog
// 顶层模块 - 管理复位逻辑
module async_rst_low_comb #(
    parameter WIDTH = 16
)(
    input  wire             rst_n,
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);
    // 控制信号
    wire reset_active;
    
    // 复位检测子模块实例化
    reset_detector u_reset_detector (
        .rst_n        (rst_n),
        .reset_active (reset_active)
    );
    
    // 数据处理子模块实例化
    data_processor #(
        .WIDTH        (WIDTH)
    ) u_data_processor (
        .in_data      (in_data),
        .reset_active (reset_active),
        .out_data     (out_data)
    );
    
endmodule

// 复位检测子模块 - 检测低电平复位信号
module reset_detector (
    input  wire rst_n,
    output wire reset_active
);
    // 复位信号取反，用于指示复位是否激活
    assign reset_active = ~rst_n;
endmodule

// 数据处理子模块 - 根据复位状态处理数据
module data_processor #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] in_data,
    input  wire             reset_active,
    output wire [WIDTH-1:0] out_data
);
    // 当复位非激活时传递输入数据，否则输出全0
    assign out_data = reset_active ? {WIDTH{1'b0}} : in_data;
endmodule