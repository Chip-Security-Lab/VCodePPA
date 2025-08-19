//SystemVerilog
module enable_rom (
    input wire clk,
    input wire en,
    input wire [3:0] addr,
    output wire [7:0] data
);
    // 内部连线
    wire [7:0] rom_data;
    wire read_enable;
    
    // 地址译码与使能控制
    enable_controller enable_ctrl (
        .clk(clk),
        .en(en),
        .read_enable(read_enable)
    );
    
    // 存储单元模块
    rom_memory memory_unit (
        .addr(addr),
        .rom_data(rom_data)
    );
    
    // 输出寄存器模块
    output_register output_reg (
        .clk(clk),
        .read_enable(read_enable),
        .rom_data(rom_data),
        .data(data)
    );
endmodule

module enable_controller (
    input wire clk,
    input wire en,
    output reg read_enable
);
    // 使能控制逻辑
    always @(posedge clk) begin
        read_enable <= en;
    end
endmodule

module rom_memory (
    input wire [3:0] addr,
    output wire [7:0] rom_data
);
    // 存储单元实现
    reg [7:0] rom [0:15];
    
    // ROM初始化
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h00; rom[9] = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00;
        rom[12] = 8'h00; rom[13] = 8'h00; rom[14] = 8'h00; rom[15] = 8'h00;
    end
    
    // 直接读取数据，不受时钟控制
    assign rom_data = rom[addr];
endmodule

module output_register (
    input wire clk,
    input wire read_enable,
    input wire [7:0] rom_data,
    output reg [7:0] data
);
    // 输出寄存器逻辑
    always @(posedge clk) begin
        if (read_enable)
            data <= rom_data;
    end
endmodule