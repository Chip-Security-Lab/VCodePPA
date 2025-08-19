//SystemVerilog
// 顶层模块：双缓冲阴影寄存器系统
module shadow_reg_double_buf #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire swap,
    input wire [WIDTH-1:0] update_data,
    output wire [WIDTH-1:0] active_data
);
    // 内部连线
    wire [WIDTH-1:0] buffer_data;
    
    // 缓冲控制器实例化
    buffer_controller #(
        .WIDTH(WIDTH)
    ) u_buffer_ctrl (
        .clk(clk),
        .swap(swap),
        .update_data(update_data),
        .buffer_data(buffer_data),
        .active_data(active_data)
    );
endmodule

// 缓冲控制器模块 - 管理双缓冲机制
module buffer_controller #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire swap,
    input wire [WIDTH-1:0] update_data,
    output wire [WIDTH-1:0] buffer_data,
    output wire [WIDTH-1:0] active_data
);
    // 寄存器定义
    reg [WIDTH-1:0] buffer_reg;
    reg [WIDTH-1:0] active_reg;
    
    // 状态控制信号
    reg swap_pending;
    
    // 将寄存器连接到输出端口
    assign buffer_data = buffer_reg;
    assign active_data = active_reg;
    
    // 更新缓冲区寄存器
    always @(posedge clk) begin
        if (!swap) begin
            buffer_reg <= update_data;
            swap_pending <= 1'b0;
        end else if (!swap_pending) begin
            swap_pending <= 1'b1;
        end
    end
    
    // 更新活动寄存器
    always @(posedge clk) begin
        if (swap && swap_pending) begin
            active_reg <= buffer_reg;
            swap_pending <= 1'b0;
        end
    end
endmodule