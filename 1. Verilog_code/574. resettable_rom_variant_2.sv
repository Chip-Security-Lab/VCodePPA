//SystemVerilog
module resettable_rom (
    input clk,
    input rst,
    input [3:0] addr,
    output reg [7:0] data
);
    // 使用reg数组存储ROM内容
    reg [7:0] rom_data [0:15];
    reg [3:0] addr_reg;
    
    // 预加载ROM内容
    initial begin
        rom_data[0] = 8'h12; rom_data[1] = 8'h34; rom_data[2] = 8'h56; rom_data[3] = 8'h78;
        rom_data[4] = 8'h9A; rom_data[5] = 8'hBC; rom_data[6] = 8'hDE; rom_data[7] = 8'hF0;
        rom_data[8] = 8'h00; rom_data[9] = 8'h00; rom_data[10] = 8'h00; rom_data[11] = 8'h00;
        rom_data[12] = 8'h00; rom_data[13] = 8'h00; rom_data[14] = 8'h00; rom_data[15] = 8'h00;
    end
    
    // 合并时序逻辑，同时处理地址寄存和数据输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_reg <= 4'h0;
            data <= 8'h00;
        end else begin
            addr_reg <= addr;
            data <= rom_data[addr_reg];
        end
    end
endmodule