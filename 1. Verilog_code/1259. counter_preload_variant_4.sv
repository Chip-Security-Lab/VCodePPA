//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module counter_preload #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  load,
    input                  en,
    input      [WIDTH-1:0] data,
    output     [WIDTH-1:0] cnt
);
    // 内部信号定义
    wire [WIDTH-1:0] next_count;
    wire             update_count;
    
    // 计数器组合逻辑单元实例化
    counter_combinational #(
        .WIDTH(WIDTH)
    ) comb_unit (
        .load        (load),
        .en          (en),
        .current_cnt (cnt),
        .data        (data),
        .next_cnt    (next_count),
        .update_en   (update_count)
    );
    
    // 计数器时序逻辑单元实例化
    counter_sequential #(
        .WIDTH(WIDTH)
    ) seq_unit (
        .clk         (clk),
        .update_en   (update_count),
        .next_value  (next_count),
        .count       (cnt)
    );
    
endmodule

// 组合逻辑模块 - 负责计算下一个计数值和控制信号
module counter_combinational #(
    parameter WIDTH = 4
)(
    input                  load,
    input                  en,
    input      [WIDTH-1:0] current_cnt,
    input      [WIDTH-1:0] data,
    output reg [WIDTH-1:0] next_cnt,
    output                 update_en
);
    // 决定是否需要更新计数值 - 纯组合逻辑
    assign update_en = load || en;
    
    // 计算下一个计数值 - 使用always块替代条件运算符
    always @(*) begin
        if (load) begin
            next_cnt = data;
        end
        else begin
            if (en) begin
                next_cnt = current_cnt + 1'b1;
            end
            else begin
                next_cnt = current_cnt;
            end
        end
    end
    
endmodule

// 时序逻辑模块 - 负责存储当前计数值
module counter_sequential #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  update_en,
    input      [WIDTH-1:0] next_value,
    output reg [WIDTH-1:0] count
);
    // 更新计数寄存器 - 纯时序逻辑
    always @(posedge clk) begin
        if (update_en) begin
            count <= next_value;
        end
    end
    
endmodule