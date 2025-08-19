//SystemVerilog
module WatchdogController #(
    parameter TIMEOUT = 16'hFFFF
)(
    input clk, rst_n,
    input refresh,
    output reg system_reset
);
    reg [15:0] wdt_counter;
    reg [1:0] refresh_sync;
    wire refresh_edge;
    wire counter_zero;

    // 输入同步
    always @(posedge clk) begin
        refresh_sync <= {refresh_sync[0], refresh};
    end

    // 刷新边沿检测
    assign refresh_edge = refresh_sync[1];

    // 计数器状态检测
    assign counter_zero = (wdt_counter == 0);

    // 计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= TIMEOUT;
        end else if (refresh_edge) begin
            wdt_counter <= TIMEOUT;
        end else if (!counter_zero) begin
            wdt_counter <= wdt_counter - 1;
        end
    end

    // 系统复位控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_reset <= 0;
        end else begin
            system_reset <= counter_zero & !refresh_edge;
        end
    end
endmodule