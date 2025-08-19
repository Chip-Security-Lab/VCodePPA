//SystemVerilog
// 顶层模块
module counter_shift_load #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire load,
    input wire shift,
    input wire [WIDTH-1:0] data,
    output wire [WIDTH-1:0] cnt
);
    // 内部连线
    wire [WIDTH-1:0] next_cnt;
    wire [WIDTH-1:0] current_cnt;
    
    // 实例化控制逻辑子模块
    control_logic #(
        .WIDTH(WIDTH)
    ) control_unit (
        .load(load),
        .shift(shift),
        .data(data),
        .current_cnt(current_cnt),
        .next_cnt(next_cnt)
    );
    
    // 实例化寄存器子模块
    register_unit #(
        .WIDTH(WIDTH)
    ) reg_unit (
        .clk(clk),
        .next_value(next_cnt),
        .current_value(current_cnt)
    );
    
    // 将内部状态连接到输出
    assign cnt = current_cnt;
    
endmodule

// 控制逻辑子模块 - 处理下一状态的计算
module control_logic #(
    parameter WIDTH = 4
)(
    input wire load,
    input wire shift,
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] current_cnt,
    output reg [WIDTH-1:0] next_cnt
);
    always @(*) begin
        if (load)
            next_cnt = data;
        else if (shift)
            next_cnt = {current_cnt[WIDTH-2:0], current_cnt[WIDTH-1]};
        else
            next_cnt = current_cnt;
    end
endmodule

// 寄存器子模块 - 存储计数器当前状态
module register_unit #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire [WIDTH-1:0] next_value,
    output reg [WIDTH-1:0] current_value
);
    always @(posedge clk) begin
        current_value <= next_value;
    end
endmodule