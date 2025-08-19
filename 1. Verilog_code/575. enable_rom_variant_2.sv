//SystemVerilog
module enable_rom (
    input clk,
    input en,  // 使能信号
    input [3:0] addr,
    output [7:0] data
);
    // 内部信号
    wire [7:0] rom_data;
    
    // 实例化ROM存储子模块
    rom_storage rom_inst (
        .addr(addr),
        .data(rom_data)
    );
    
    // 实例化输出控制子模块
    output_control ctrl_inst (
        .clk(clk),
        .en(en),
        .rom_data(rom_data),
        .data(data)
    );
endmodule

module rom_storage #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] data
);
    // ROM存储器实现
    reg [DATA_WIDTH-1:0] rom [0:DEPTH-1];
    
    // 初始化ROM内容
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'h00; rom[9] = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00;
        rom[12] = 8'h00; rom[13] = 8'h00; rom[14] = 8'h00; rom[15] = 8'h00;
    end
    
    // 组合逻辑读取ROM
    assign data = rom[addr];
endmodule

module output_control #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] rom_data,
    output reg [DATA_WIDTH-1:0] data
);
    // 时序逻辑控制输出
    always @(posedge clk) begin
        if (en) 
            data <= rom_data;
    end
endmodule