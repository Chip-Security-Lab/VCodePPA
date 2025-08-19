module WatchdogController #(
    parameter TIMEOUT = 16'hFFFF
)(
    input clk, rst_n,
    input refresh,
    output reg system_reset
);
    reg [15:0] wdt_counter;
    reg [1:0] refresh_sync;

    // 输入同步
    always @(posedge clk) begin
        refresh_sync <= {refresh_sync[0], refresh};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wdt_counter <= TIMEOUT;
            system_reset <= 0;
        end else begin
            // 看门狗刷新逻辑
            if (refresh_sync[1]) begin
                wdt_counter <= TIMEOUT;
                system_reset <= 0;
            end else if (wdt_counter != 0) begin
                wdt_counter <= wdt_counter - 1;
                system_reset <= 0;
            end else begin
                system_reset <= 1;
            end
        end
    end
endmodule
