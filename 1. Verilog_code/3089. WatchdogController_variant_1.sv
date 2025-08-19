//SystemVerilog
module WatchdogController #(
    parameter TIMEOUT = 16'hFFFF
)(
    input wire clk, rst_n,
    input wire refresh,
    output reg system_reset
);
    reg [15:0] wdt_counter;
    reg [1:0] refresh_sync;
    wire refresh_detected;
    wire timeout_reached;
    
    // 使用wire提前计算条件，减少逻辑深度
    assign refresh_detected = refresh_sync[1];
    assign timeout_reached = (wdt_counter == 16'h0001);
    
    // 输入同步 - 使用非阻塞赋值提高时序性能
    always @(posedge clk) begin
        refresh_sync <= {refresh_sync[0], refresh};
    end

    // 计数器逻辑优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= TIMEOUT;
        end else if (refresh_detected) begin
            wdt_counter <= TIMEOUT;
        end else if (wdt_counter != 16'h0000) begin
            wdt_counter <= wdt_counter - 16'h0001;
        end
    end
    
    // 复位信号控制逻辑分离，减少关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_reset <= 1'b0;
        end else if (refresh_detected) begin
            system_reset <= 1'b0;
        end else if (timeout_reached) begin
            system_reset <= 1'b1;
        end
    end
endmodule