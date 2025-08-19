//SystemVerilog
// 顶层模块
module counter_sync_inc #(
    parameter WIDTH = 8
)(
    input  wire             clk,      // 时钟信号
    input  wire             rst_n,    // 低电平有效复位信号
    input  wire             en,       // 使能信号
    output wire [WIDTH-1:0] cnt       // 计数器输出
);
    // 内部信号
    wire [WIDTH-1:0] next_cnt;
    wire [WIDTH-1:0] current_cnt;
    
    // 状态寄存器实例化
    counter_register #(
        .WIDTH(WIDTH)
    ) u_register (
        .clk           (clk),
        .rst_n         (rst_n),
        .next_value    (next_cnt),
        .current_value (current_cnt)
    );
    
    // 计数逻辑实例化
    counter_incrementer #(
        .WIDTH(WIDTH)
    ) u_incrementer (
        .current_value (current_cnt),
        .enable        (en),
        .next_value    (next_cnt)
    );
    
    // 输出赋值
    assign cnt = current_cnt;
    
endmodule

// 状态寄存器模块 - 负责存储当前计数值
module counter_register #(
    parameter WIDTH = 8
)(
    input  wire             clk,           // 时钟信号
    input  wire             rst_n,         // 低电平有效复位信号
    input  wire [WIDTH-1:0] next_value,    // 下一个计数值
    output reg  [WIDTH-1:0] current_value  // 当前计数值
);
    // 时序逻辑：同步复位寄存器
    always @(posedge clk) begin
        if (!rst_n) 
            current_value <= {WIDTH{1'b0}}; // 复位时计数器清零
        else 
            current_value <= next_value;    // 更新为下一个计数值
    end
endmodule

// 计数逻辑模块 - 使用补码加法实现递增
module counter_incrementer #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] current_value, // 当前计数值
    input  wire             enable,        // 计数使能信号
    output wire [WIDTH-1:0] next_value     // 计算得到的下一个计数值
);
    // 组合逻辑：使能时加1，否则保持当前值
    // 使用补码加法实现递增操作
    wire [WIDTH-1:0] increment = {{(WIDTH-1){1'b0}}, 1'b1}; // 增量值1
    wire [WIDTH-1:0] add_result;
    
    // 使用补码加法实现
    assign add_result = current_value + increment;
    
    // 根据使能选择新值
    assign next_value = enable ? add_result : current_value;
endmodule