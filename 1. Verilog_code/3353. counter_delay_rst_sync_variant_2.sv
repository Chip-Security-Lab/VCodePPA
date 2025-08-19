//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module counter_delay_rst_sync #(
    parameter DELAY_CYCLES = 16
)(
    input  wire clk,
    input  wire raw_rst_n,
    output reg  delayed_rst_n
);
    // 同步器级联触发器
    reg [1:0] sync_stages;
    // 计数器使用最小所需位宽
    reg [$clog2(DELAY_CYCLES):0] delay_counter;
    
    always @(posedge clk or negedge raw_rst_n) begin
        if (!raw_rst_n) begin
            sync_stages <= 2'b00;
            delay_counter <= '0;
            delayed_rst_n <= 1'b0;
        end else begin
            // 同步raw_rst_n信号
            sync_stages <= {sync_stages[0], 1'b1};
            
            // 优化后的比较逻辑
            if (!sync_stages[1]) begin
                // 复位激活时重置计数器
                delay_counter <= '0;
                delayed_rst_n <= 1'b0;
            end else if (!delayed_rst_n) begin
                // 仅在复位未释放时计数
                if (delay_counter >= DELAY_CYCLES - 1) begin
                    // 计数完成，释放复位
                    delayed_rst_n <= 1'b1;
                    delay_counter <= '0; // 可选：重置计数器
                end else begin
                    // 继续计数
                    delay_counter <= delay_counter + 1'b1;
                end
            end
            // 如果delayed_rst_n已经为1，不需要额外操作
        end
    end
endmodule

`default_nettype wire