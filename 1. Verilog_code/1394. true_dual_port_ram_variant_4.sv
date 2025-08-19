//SystemVerilog
module true_dual_port_ram #(
    parameter DW = 16,    // 数据宽度
    parameter AW = 8      // 地址宽度
) (
    input clk_a, clk_b,         // 两个端口的时钟
    input [AW-1:0] addr_a, addr_b,  // 地址输入
    input wr_a, wr_b,           // 写使能
    input [DW-1:0] din_a, din_b,    // 数据输入
    output reg [DW-1:0] dout_a, dout_b  // 数据输出
);
    // 存储器声明
    reg [DW-1:0] mem [(1<<AW)-1:0];
    
    // 端口A的读写操作 - 优化为读优先逻辑
    always @(posedge clk_a) begin
        if(wr_a) 
            mem[addr_a] <= din_a;
    end
    
    always @(posedge clk_a) begin
        dout_a <= mem[addr_a];
    end
    
    // 端口B的读写操作 - 优化为读优先逻辑
    always @(posedge clk_b) begin
        if(wr_b)
            mem[addr_b] <= din_b;
    end
    
    always @(posedge clk_b) begin
        dout_b <= mem[addr_b];
    end
endmodule