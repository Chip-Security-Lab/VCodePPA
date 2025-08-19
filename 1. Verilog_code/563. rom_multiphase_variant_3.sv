//SystemVerilog
// 顶层模块
module rom_multiphase #(
    parameter PHASES = 4
)(
    input clk,
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] data
);
    wire [7:0] addr_combined;
    assign addr_combined = {phase, addr};
    
    // 实例化存储子模块
    rom_memory_block u_rom_memory (
        .clk(clk),
        .addr(addr_combined),
        .data(data)
    );
endmodule

// 内存读取子模块
module rom_memory_block (
    input clk,
    input [7:0] addr,
    output reg [7:0] data
);
    // 内存阵列声明
    reg [7:0] mem [0:255];
    
    // 初始化内存值
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    // 寄存器化读取以提高性能
    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule