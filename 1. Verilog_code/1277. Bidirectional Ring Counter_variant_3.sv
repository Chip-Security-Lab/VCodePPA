//SystemVerilog
module bidir_ring_counter (
    input  wire       clk,     // 系统时钟
    input  wire       rst,     // 异步复位信号
    input  wire       dir,     // 方向控制: 0=左移, 1=右移
    output reg  [3:0] q_out    // 计数器输出
);
    // 内部信号定义
    reg  [3:0] current_value;  // 当前计数值
    reg  [3:0] next_value;     // 下一个计数值
    wire [3:0] shift_right;    // 右移操作结果
    wire [3:0] shift_left;     // 左移操作结果
    
    // 计算移位操作结果
    assign shift_right = {current_value[0], current_value[3:1]};  // 右移: [a,b,c,d] -> [d,a,b,c]
    assign shift_left = {current_value[2:0], current_value[3]};   // 左移: [a,b,c,d] -> [b,c,d,a]
    
    // 计算下一状态逻辑 - 组合逻辑部分
    always @(*) begin
        if (dir)
            next_value = shift_right;
        else
            next_value = shift_left;
    end
    
    // 状态寄存器 - 时序逻辑部分
    always @(posedge clk) begin
        if (rst)
            current_value <= 4'b0001;  // 复位状态
        else
            current_value <= next_value;
    end
    
    // 输出逻辑 - 流水线寄存器
    always @(posedge clk) begin
        if (rst)
            q_out <= 4'b0001;
        else
            q_out <= current_value;
    end
endmodule