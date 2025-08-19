//SystemVerilog
module dual_port_rom (
    input wire clk,
    input wire [3:0] addr_a, addr_b,
    output reg [7:0] data_a, data_b
);
    // ROM存储器定义
    reg [7:0] rom_memory [0:15];
    
    // 地址寄存器，用于分段数据路径
    reg [3:0] addr_a_reg, addr_b_reg;
    
    // 初始化ROM内容
    initial begin
        rom_memory[0] = 8'h12; rom_memory[1] = 8'h34; 
        rom_memory[2] = 8'h56; rom_memory[3] = 8'h78;
        rom_memory[4] = 8'h9A; rom_memory[5] = 8'hBC; 
        rom_memory[6] = 8'hDE; rom_memory[7] = 8'hF0;
        rom_memory[8] = 8'h11; rom_memory[9] = 8'h22; 
        rom_memory[10] = 8'h33; rom_memory[11] = 8'h44;
        rom_memory[12] = 8'h55; rom_memory[13] = 8'h66; 
        rom_memory[14] = 8'h77; rom_memory[15] = 8'h88;
    end
    
    // 阶段1: 地址输入寄存器
    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
    end
    
    // 阶段2: 数据读取输出
    always @(posedge clk) begin
        data_a <= rom_memory[addr_a_reg];
        data_b <= rom_memory[addr_b_reg];
    end
    
endmodule