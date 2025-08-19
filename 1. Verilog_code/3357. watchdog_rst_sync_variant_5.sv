//SystemVerilog - IEEE 1364-2005
module watchdog_rst_sync (
    input  wire clk,
    input  wire ext_rst_n,
    input  wire watchdog_trigger,
    output reg  combined_rst_n
);
    reg ext_rst_meta;
    reg ext_rst_sync;
    wire watchdog_rst_n;
    
    // 将多级同步寄存器拆分，实现前向寄存器重定时
    always @(posedge clk or negedge ext_rst_n)
        if (!ext_rst_n)
            ext_rst_meta <= 1'b0;
        else
            ext_rst_meta <= 1'b1;
    
    always @(posedge clk or negedge ext_rst_n)
        if (!ext_rst_n)
            ext_rst_sync <= 1'b0;
        else
            ext_rst_sync <= ext_rst_meta;
    
    // 将watchdog_trigger逻辑转化为组合逻辑
    assign watchdog_rst_n = watchdog_trigger ? 1'b0 : 1'b1;
    
    // 将寄存器移至组合逻辑后面
    always @(posedge clk or negedge ext_rst_n)
        if (!ext_rst_n)
            combined_rst_n <= 1'b0;
        else
            combined_rst_n <= ext_rst_sync & watchdog_rst_n;
endmodule