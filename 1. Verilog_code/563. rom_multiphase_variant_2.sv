//SystemVerilog
// 顶层模块 - 多相位ROM控制器
module rom_multiphase #(
    parameter PHASES = 4
)(
    input clk,
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] data
);
    // 地址生成与选择
    wire [7:0] full_addr;
    
    // ROM存储模块实例
    rom_storage rom_inst (
        .clk(clk),
        .addr(full_addr),
        .data(data)
    );
    
    // 地址生成模块实例
    addr_generator addr_gen_inst (
        .phase(phase),
        .addr(addr),
        .full_addr(full_addr)
    );
endmodule

// 地址生成器子模块
module addr_generator (
    input [1:0] phase,
    input [5:0] addr,
    output [7:0] full_addr
);
    // 将相位和地址合并为完整地址
    assign full_addr = {phase, addr};
endmodule

// ROM存储子模块
module rom_storage (
    input clk,
    input [7:0] addr,
    output reg [7:0] data
);
    // 内存声明
    reg [7:0] mem [0:255];
    
    // 内存初始化
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i & 8'hFF;
    end
    
    // 数据读取逻辑（增加寄存器以改善时序）
    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule