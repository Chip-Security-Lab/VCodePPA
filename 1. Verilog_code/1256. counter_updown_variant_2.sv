//SystemVerilog
// 顶层模块
module counter_updown #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    input wire dir,
    input wire en,
    output wire [WIDTH-1:0] cnt
);
    // 内部信号
    reg [WIDTH-1:0] next_cnt_reg;
    reg dir_reg, en_reg;
    wire [WIDTH-1:0] current_cnt;
    
    // 缓冲寄存器用于降低高扇出
    reg [WIDTH-1:0] current_value_buf1;
    reg [WIDTH-1:0] current_value_buf2;
    
    // 将计数值输出
    assign cnt = current_cnt;
    
    // 寄存控制输入信号和创建扇出缓冲
    always @(posedge clk) begin
        if (rst) begin
            dir_reg <= 1'b0;
            en_reg <= 1'b0;
            next_cnt_reg <= {WIDTH{1'b0}};
            current_value_buf1 <= {WIDTH{1'b0}};
            current_value_buf2 <= {WIDTH{1'b0}};
        end else begin
            dir_reg <= dir;
            en_reg <= en;
            next_cnt_reg <= current_cnt;
            current_value_buf1 <= next_cnt_reg;
            current_value_buf2 <= next_cnt_reg;
        end
    end
    
    // 实例化控制逻辑模块 - 使用缓冲信号降低扇出
    counter_control #(
        .WIDTH(WIDTH)
    ) control_unit (
        .current_value_up(current_value_buf1),
        .current_value_down(current_value_buf2),
        .direction(dir_reg),
        .enable(en_reg),
        .next_value(current_cnt)
    );
    
endmodule

// 控制逻辑子模块
module counter_control #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] current_value_up,   // 向上计数使用的缓冲
    input wire [WIDTH-1:0] current_value_down, // 向下计数使用的缓冲
    input wire direction,
    input wire enable,
    output wire [WIDTH-1:0] next_value
);
    // 拆分计算路径，减少关键路径延迟
    wire [WIDTH-1:0] count_up_value;
    wire [WIDTH-1:0] count_down_value;
    
    // 并行计算向上和向下计数结果
    assign count_up_value = current_value_up + 1'b1;
    assign count_down_value = current_value_down - 1'b1;
    
    // 最终根据方向和使能信号选择下一个计数值
    assign next_value = enable ? (direction ? count_up_value : count_down_value) : 
                       (direction ? current_value_up : current_value_down);
    
endmodule