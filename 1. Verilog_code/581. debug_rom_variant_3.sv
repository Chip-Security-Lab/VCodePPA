//SystemVerilog
module debug_rom (
    input clk,
    input [3:0] addr,
    input debug_en,
    input valid,         // 数据有效信号
    output reg ready,    // 接收就绪信号
    output reg [7:0] data,
    output reg [3:0] debug_addr
);

    reg [7:0] rom [0:15];
    reg valid_reg;       // 有效信号寄存器
    reg [7:0] rom_data_reg;  // ROM数据缓冲寄存器
    reg [3:0] addr_reg;      // 地址缓冲寄存器
    reg debug_en_reg;        // 调试使能缓冲寄存器
    reg data_valid;          // 数据有效标志

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
    end

    always @(posedge clk) begin
        valid_reg <= valid;  // 寄存有效信号
        addr_reg <= addr;
        debug_en_reg <= debug_en;
        
        if (valid_reg && ready) begin
            rom_data_reg <= rom[addr_reg];  // 缓冲ROM数据
            if (debug_en_reg)
                debug_addr <= addr_reg;
            data <= rom_data_reg;
            data_valid <= 1'b1;  // 数据有效
        end else if (!valid_reg) begin
            data_valid <= 1'b0;  // 清除数据有效标志
        end
    end

    // 组合逻辑生成ready信号
    always @(*) begin
        ready = !data_valid || (valid_reg && !ready);  // 当数据无效或正在传输时准备接收
    end

endmodule