//SystemVerilog
module sync_dual_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                                // 时钟信号
    input wire rst,                                // 复位信号
    input wire we_a, we_b,                         // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,    // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,       // 数据输入
    input wire [DATA_WIDTH/8-1:0] byte_en_a, byte_en_b, // 字节使能
    output reg [DATA_WIDTH-1:0] dout_a, dout_b      // 数据输出
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];  // 内存阵列
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            // 扁平化端口A的写操作逻辑
            for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                if (we_a && byte_en_a[i]) 
                    ram[addr_a][i*8 +: 8] <= din_a[i*8 +: 8];
            end
            
            // 扁平化端口B的写操作逻辑
            for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                if (we_b && byte_en_b[i]) 
                    ram[addr_b][i*8 +: 8] <= din_b[i*8 +: 8];
            end
            
            // 读操作部分
            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
        end
    end
endmodule