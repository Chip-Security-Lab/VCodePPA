//SystemVerilog
module reset_cdc_sync(
    input wire dst_clk,
    input wire async_rst_in,
    output reg synced_rst
);
    // 使用两级寄存器同步链实现异步复位的同步化
    reg meta_flop;
    
    // 两级寄存器都使用异步复位，保证复位信号立即生效
    always @(posedge dst_clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            // 异步置位
            {synced_rst, meta_flop} <= 2'b11;
        end else begin
            // 正常时钟边沿转移
            meta_flop <= 1'b0;
            synced_rst <= meta_flop;
        end
    end
endmodule