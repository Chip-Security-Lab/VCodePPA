//SystemVerilog
module watchdog_rst_sync (
    input  wire clk,
    input  wire ext_rst_n,
    input  wire watchdog_trigger,
    output reg  combined_rst_n
);
    reg ext_rst_sync_1;
    wire ext_rst_sync_0;
    reg watchdog_rst_n;
    
    // 外部复位同步 - 前向重定时优化
    // 将第一级寄存器移除，直接使用输入信号
    assign ext_rst_sync_0 = 1'b1;
    
    // 第二级寄存器保留
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_sync_1 <= 1'b0;
        end
        else begin
            ext_rst_sync_1 <= ext_rst_sync_0;
        end
    end
    
    // 看门狗复位逻辑 - 前向重定时优化
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            watchdog_rst_n <= 1'b1;
        else
            watchdog_rst_n <= ~watchdog_trigger;
    end
    
    // 合并复位逻辑
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            combined_rst_n <= 1'b0;
        else
            combined_rst_n <= ext_rst_sync_1 & watchdog_rst_n;
    end
endmodule