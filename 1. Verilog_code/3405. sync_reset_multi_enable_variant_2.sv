//SystemVerilog
// SystemVerilog
// 顶层模块
module watchdog_reset_gen #(
    parameter TIMEOUT = 8
)(
    input  wire clk,
    input  wire watchdog_kick,
    output wire watchdog_reset
);
    // 内部信号
    wire counter_timeout;
    
    // 子模块实例化
    watchdog_counter #(
        .TIMEOUT(TIMEOUT)
    ) counter_inst (
        .clk            (clk),
        .watchdog_kick  (watchdog_kick),
        .counter_timeout(counter_timeout)
    );
    
    watchdog_output_stage output_stage_inst (
        .clk            (clk),
        .counter_timeout(counter_timeout),
        .watchdog_reset (watchdog_reset)
    );
    
endmodule

// 计数器子模块
module watchdog_counter #(
    parameter TIMEOUT = 8
)(
    input  wire clk,
    input  wire watchdog_kick,
    output wire counter_timeout
);
    // 内部计数器
    reg [3:0] counter;
    
    // 计算超时条件
    assign counter_timeout = (counter >= TIMEOUT);
    
    // 计数器逻辑
    always @(posedge clk) begin
        if (watchdog_kick)
            counter <= 4'b0;
        else if (counter < TIMEOUT)
            counter <= counter + 1'b1;
    end
    
endmodule

// 输出阶段子模块
module watchdog_output_stage (
    input  wire clk,
    input  wire counter_timeout,
    output reg  watchdog_reset
);
    // 前向寄存器重定时
    always @(posedge clk) begin
        watchdog_reset <= counter_timeout;
    end
    
endmodule