//SystemVerilog
// 顶层模块
module decade_counter (
    input wire clk, reset,
    output wire [3:0] counter,
    output wire decade_pulse
);
    // 内部连线
    wire count_max;
    wire [3:0] next_count;

    // 检测计数器达到最大值的子模块
    counter_detector u_detector (
        .counter(counter),
        .count_max(count_max)
    );

    // 计数器逻辑子模块
    counter_logic u_counter_logic (
        .current_count(counter),
        .count_max(count_max),
        .next_count(next_count)
    );

    // 计数器寄存器子模块
    counter_register u_counter_register (
        .clk(clk),
        .reset(reset),
        .next_count(next_count),
        .counter(counter)
    );

    // 输出脉冲信号
    assign decade_pulse = count_max;

endmodule

// 检测计数器是否达到最大值的子模块
module counter_detector (
    input wire [3:0] counter,
    output wire count_max
);
    // 当计数器达到9时输出高电平
    assign count_max = (counter == 4'd9);
endmodule

// 计数器逻辑子模块 - 计算下一个计数值
module counter_logic (
    input wire [3:0] current_count,
    input wire count_max,
    output wire [3:0] next_count
);
    // 如果计数到最大值则复位到0，否则加1
    assign next_count = count_max ? 4'd0 : current_count + 1'b1;
endmodule

// 计数器寄存器子模块 - 存储当前计数值
module counter_register (
    input wire clk, reset,
    input wire [3:0] next_count,
    output reg [3:0] counter
);
    // 在时钟上升沿更新计数值
    always @(posedge clk) begin
        if (reset)
            counter <= 4'd0;
        else
            counter <= next_count;
    end
endmodule