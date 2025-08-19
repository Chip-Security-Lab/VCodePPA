//SystemVerilog
///////////////////////////////////////////
// 顶层模块: 参数化时钟分频器
///////////////////////////////////////////
module param_clock_divider #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output wire clock_o
);
    // 内部连线
    wire counter_max_reached;
    wire [$clog2(DIVISOR)-1:0] count_value;
    
    // 计数器子模块实例化
    counter_module #(
        .DIVISOR(DIVISOR)
    ) counter_inst (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .count_o(count_value),
        .max_reached_o(counter_max_reached)
    );
    
    // 时钟输出生成子模块实例化
    clock_toggle_module clock_toggle_inst (
        .clock_i(clock_i),
        .reset_i(reset_i),
        .toggle_i(counter_max_reached),
        .clock_o(clock_o)
    );
    
endmodule

///////////////////////////////////////////
// 子模块1: 计数器模块
///////////////////////////////////////////
module counter_module #(
    parameter DIVISOR = 10
)(
    input wire clock_i,
    input wire reset_i,
    output reg [$clog2(DIVISOR)-1:0] count_o,
    output wire max_reached_o
);
    // 组合逻辑部分
    wire [$clog2(DIVISOR)-1:0] next_count;
    wire count_reset;
    
    // 组合逻辑: 下一计数值计算
    assign next_count = (count_o == DIVISOR-1) ? '0 : (count_o + 1'b1);
    
    // 组合逻辑: 最大值检测比较器
    assign max_reached_o = (count_o == DIVISOR-1);
    
    // 组合逻辑: 复位条件
    assign count_reset = reset_i;
    
    // 时序逻辑部分
    always @(posedge clock_i) begin
        if (count_reset) begin
            count_o <= '0;
        end else begin
            count_o <= next_count;
        end
    end
    
endmodule

///////////////////////////////////////////
// 子模块2: 时钟切换模块
///////////////////////////////////////////
module clock_toggle_module (
    input wire clock_i,
    input wire reset_i,
    input wire toggle_i,
    output reg clock_o
);
    // 组合逻辑部分
    wire next_clock_state;
    wire toggle_condition;
    
    // 组合逻辑: 时钟切换条件
    assign toggle_condition = toggle_i & ~reset_i;
    
    // 组合逻辑: 下一时钟状态计算
    assign next_clock_state = toggle_condition ? ~clock_o : clock_o;
    
    // 时序逻辑部分
    always @(posedge clock_i) begin
        if (reset_i) begin
            clock_o <= 1'b0;
        end else begin
            clock_o <= next_clock_state;
        end
    end
    
endmodule