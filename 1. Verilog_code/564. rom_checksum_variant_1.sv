//SystemVerilog
module rom_checksum #(
    parameter AW = 6
)(
    input wire clk,
    input wire [AW-1:0] addr,
    output reg [8:0] data
);
    // 合并存储器为单一部分以减少资源使用
    reg [7:0] mem [0:((1<<AW)-1)];
    
    // 优化流水线寄存器
    reg [AW-1:0] addr_r;
    reg [7:0] mem_data;
    
    // 初始化存储器
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1) begin
            mem[i] = i & 8'hFF;
        end
    end
    
    // 流水线第一级：地址寄存和直接内存访问
    always @(posedge clk) begin
        addr_r <= addr;
        mem_data <= mem[addr];
    end
    
    // 流水线第二级：直接计算奇偶校验并构建输出
    always @(posedge clk) begin
        data <= {^mem_data, mem_data};
    end
endmodule