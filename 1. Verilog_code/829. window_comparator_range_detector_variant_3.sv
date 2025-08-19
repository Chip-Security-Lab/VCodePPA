//SystemVerilog
module window_comparator_range_detector(
    input wire [9:0] analog_value,
    input wire [9:0] window_center,
    input wire [9:0] window_width,
    output reg in_window
);
    // 使用参数化的设计以便于合成工具优化
    parameter WIDTH = 10;
    
    // 使用寄存器减少关键路径
    reg [WIDTH-1:0] half_width;
    reg [WIDTH-1:0] lower_threshold;
    reg [WIDTH-1:0] upper_threshold;
    
    // 使用优化的比较逻辑
    always @(*) begin
        // 计算半宽度时避免使用移位操作
        half_width = {1'b0, window_width[WIDTH-1:1]};
        
        // 计算阈值
        lower_threshold = window_center - half_width;
        upper_threshold = window_center + half_width;
        
        // 使用范围检查代替独立比较
        if ((analog_value - lower_threshold) <= (upper_threshold - lower_threshold))
            in_window = 1'b1;
        else
            in_window = 1'b0;
    end
endmodule