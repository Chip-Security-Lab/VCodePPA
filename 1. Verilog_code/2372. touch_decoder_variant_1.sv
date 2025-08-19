//SystemVerilog
// 顶层模块：触摸屏坐标处理系统
module touch_decoder (
    input [11:0] x_raw, y_raw,
    output [10:0] x_pos, y_pos
);
    // 内部连接信号
    wire [10:0] x_processed, y_processed;
    
    // X坐标处理实例化
    coordinate_processor x_processor (
        .raw_value(x_raw),
        .processed_value(x_pos),
        .process_mode(1'b0),  // 0: 校准模式 (添加偏移)
        .process_param(5)     // 偏移量
    );
    
    // Y坐标处理实例化
    coordinate_processor y_processor (
        .raw_value(y_raw),
        .processed_value(y_pos),
        .process_mode(1'b1),  // 1: 缩小模式 (右移)
        .process_param(1)     // 右移位数
    );
endmodule

// 统一的坐标处理模块
module coordinate_processor (
    input [11:0] raw_value,
    input process_mode,       // 0: 校准模式, 1: 缩小模式
    input [10:0] process_param, // 处理参数 (偏移量或右移位数)
    output [10:0] processed_value
);
    // 内部信号
    wire [10:0] scaled_value;
    
    // 子模块实例化
    coordinate_scaler scaler (
        .raw_value(raw_value),
        .scaled_value(scaled_value)
    );
    
    // 基于处理模式选择后处理方法
    coordinate_post_processor post_processor (
        .scaled_value(scaled_value),
        .process_mode(process_mode),
        .process_param(process_param),
        .processed_value(processed_value)
    );
endmodule

// 坐标缩放子模块
module coordinate_scaler (
    input [11:0] raw_value,
    output [10:0] scaled_value
);
    // 丢弃最低位，实现初始缩放
    assign scaled_value = raw_value[11:1];
endmodule

// 坐标后处理子模块 - 整合校准与缩小功能
module coordinate_post_processor (
    input [10:0] scaled_value,
    input process_mode,        // 0: 校准模式, 1: 缩小模式
    input [10:0] process_param, // 处理参数
    output reg [10:0] processed_value
);
    // 使用if-else结构替代case语句
    always @(*) begin
        if (process_mode == 1'b0) begin
            processed_value = scaled_value + process_param;  // 校准模式：添加偏移
        end
        else if (process_mode == 1'b1) begin
            processed_value = scaled_value >> process_param; // 缩小模式：右移
        end
        else begin
            processed_value = scaled_value; // 默认情况
        end
    end
endmodule