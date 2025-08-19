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
    wire refresh_detected;
    wire counter_expired;

    // 检测有效的刷新信号
    assign refresh_detected = refresh_sync[0] & ~refresh_sync[1];
    
    // 计数器到期检测
    assign counter_expired = (wdt_counter == 16'd1);

    // 输入同步 - 使用二级触发器减少亚稳态风险
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            refresh_sync <= 2'b00;
        else
            refresh_sync <= {refresh_sync[0], refresh};
    end

    // 看门狗计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= TIMEOUT;
            system_reset <= 1'b0;
        end else begin
            if (refresh_detected || refresh_sync[1]) begin
                // 刷新看门狗
                wdt_counter <= TIMEOUT;
            end else if (|wdt_counter) begin
                // 使用归约运算符检查非零，比比较更高效
                wdt_counter <= wdt_counter - 1'b1;
            end
        end
    end
    
    // 分离复位逻辑，减少关键路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            system_reset <= 1'b0;
        else if (refresh_detected || refresh_sync[1])
            system_reset <= 1'b0;
        else if (counter_expired)
            system_reset <= 1'b1;
    end
endmodule