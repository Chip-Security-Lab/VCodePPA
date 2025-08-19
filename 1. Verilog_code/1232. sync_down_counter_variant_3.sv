//SystemVerilog
// 顶层模块
module sync_down_counter #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output wire [WIDTH-1:0] q_out
);
    // 内部连线
    wire [WIDTH-1:0] next_count;
    wire [WIDTH-1:0] reset_value;
    
    // 实例化子模块
    counter_control_unit #(
        .WIDTH(WIDTH)
    ) control_unit (
        .enable(enable),
        .current_count(q_out),
        .next_count(next_count)
    );
    
    reset_value_generator #(
        .WIDTH(WIDTH)
    ) reset_gen (
        .reset_value(reset_value)
    );
    
    counter_register #(
        .WIDTH(WIDTH)
    ) count_reg (
        .clk(clk),
        .rst(rst),
        .next_count(next_count),
        .reset_value(reset_value),
        .q_out(q_out)
    );
    
endmodule

// 计数器控制单元 - 负责计数逻辑，使用条件求和算法实现减法
module counter_control_unit #(
    parameter WIDTH = 8
)(
    input  wire enable,
    input  wire [WIDTH-1:0] current_count,
    output wire [WIDTH-1:0] next_count
);
    // 条件求和减法算法实现
    wire [WIDTH-1:0] ones_complement;
    wire [WIDTH:0] sum;
    wire [WIDTH-1:0] decrement_result;
    
    // 1的补码 (取反)
    assign ones_complement = ~8'b00000001;
    
    // 条件求和 (加上1的补码 + 1)
    assign sum = {1'b0, current_count} + {1'b0, ones_complement} + 1'b1;
    
    // 提取结果 (忽略进位)
    assign decrement_result = sum[WIDTH-1:0];
    
    // 计数逻辑 - 当使能时递减
    assign next_count = enable ? decrement_result : current_count;
    
endmodule

// 复位值生成器 - 生成复位时的初始值
module reset_value_generator #(
    parameter WIDTH = 8
)(
    output wire [WIDTH-1:0] reset_value
);
    // 复位值为全1
    assign reset_value = {WIDTH{1'b1}};
    
endmodule

// 计数器寄存器 - 存储当前计数值
module counter_register #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] next_count,
    input  wire [WIDTH-1:0] reset_value,
    output reg  [WIDTH-1:0] q_out
);
    // 时序逻辑 - 在时钟上升沿更新计数值
    always @(posedge clk) begin
        if (rst)
            q_out <= reset_value;  // 复位到指定值
        else
            q_out <= next_count;   // 更新为下一个计数值
    end
    
endmodule