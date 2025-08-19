//SystemVerilog
// SystemVerilog
module range_decoder(
    input [7:0] addr,
    output reg rom_sel,
    output reg ram_sel,
    output reg io_sel,
    output reg error
);
    // 直接从地址生成选择信号，无需中间变量
    always @(*) begin
        // 默认值设置
        rom_sel = (addr < 8'h40);
        ram_sel = (addr >= 8'h40) && (addr < 8'hC0);
        io_sel = (addr >= 8'hC0) && (addr < 8'hFF);
        error = (addr >= 8'hFF);
    end
endmodule