//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps

module compare_match_timer (
    input wire i_clock,        // 系统时钟
    input wire i_nreset,       // 低电平有效复位信号
    input wire i_enable,       // 计时器使能信号
    input wire [23:0] i_compare, // 比较值
    output wire o_match,        // 匹配信号输出
    output wire [23:0] o_counter // 计数器当前值
);
    // 内部连线
    wire [23:0] timer_value;
    
    // 计数器子模块实例化
    counter_module counter_inst (
        .clk(i_clock),
        .rst_n(i_nreset),
        .enable(i_enable),
        .counter_out(timer_value)
    );
    
    // 比较器子模块实例化
    comparator_module comparator_inst (
        .clk(i_clock),
        .rst_n(i_nreset),
        .enable(i_enable),
        .counter_value(timer_value),
        .compare_value(i_compare),
        .match_out(o_match)
    );
    
    // 将计数器值连接到输出
    assign o_counter = timer_value;
    
endmodule

// 计数器子模块 - 负责计数功能
module counter_module (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [23:0] counter_out
);
    // 复位处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_out <= 24'h000000;
    end
    
    // 计数逻辑
    always @(posedge clk) begin
        if (rst_n && enable)
            counter_out <= counter_out + 24'h000001;
    end
endmodule

// 比较器子模块 - 负责比较功能
module comparator_module (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [23:0] counter_value,
    input wire [23:0] compare_value,
    output reg match_out
);
    // 复位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match_out <= 1'b0;
    end
    
    // 比较匹配逻辑
    always @(posedge clk) begin
        if (rst_n)
            match_out <= (counter_value == compare_value) && enable;
    end
endmodule