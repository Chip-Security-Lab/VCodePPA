//SystemVerilog
module AdaptiveThreshold #(
    parameter WIDTH = 8,   // ADC输入位宽
    parameter ALPHA = 3    // 平均值更新权重因子
) (
    input                  clk,         // 时钟信号
    input      [WIDTH-1:0] adc_input,   // ADC输入数据
    output reg             digital_out  // 数字输出结果
);
    // 内部信号声明
    reg [WIDTH+ALPHA-1:0] avg_level;        // 平均信号电平
    reg [WIDTH+ALPHA-1:0] threshold_value;  // 阈值计算结果
    
    // 条件求和减法算法相关信号
    reg [WIDTH-1:0] avg_shifted;            // 移位后的平均值
    reg [WIDTH:0]   borrow_bits;            // 借位标志位
    reg [WIDTH-1:0] sub_result;             // 减法结果
    
    // 计算移位后的平均值
    always @(posedge clk) begin
        avg_shifted <= avg_level >> ALPHA;
    end
    
    // 使用条件求和减法算法实现减法
    always @(posedge clk) begin
        borrow_bits[0] <= 0;  // 初始无借位
        
        // 逐位计算减法结果和借位
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            sub_result[i] <= adc_input[i] ^ avg_shifted[i] ^ borrow_bits[i];
            borrow_bits[i+1] <= (~adc_input[i] & avg_shifted[i]) | 
                               (~adc_input[i] & borrow_bits[i]) | 
                               (avg_shifted[i] & borrow_bits[i]);
        end
        
        // 更新平均信号电平
        avg_level <= avg_level + {sub_result[WIDTH-1], sub_result};
    end

    // 计算阈值
    always @(posedge clk) begin
        threshold_value <= avg_shifted;
    end

    // 比较器输出生成
    always @(posedge clk) begin
        digital_out <= (adc_input > threshold_value);
    end

endmodule