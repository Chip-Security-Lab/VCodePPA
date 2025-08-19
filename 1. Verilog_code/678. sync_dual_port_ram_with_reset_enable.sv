module sync_dual_port_ram_with_reset_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                            // 时钟信号
    input wire rst,                            // 复位信号
    input wire en,                             // 使能信号
    input wire we_a, we_b,                     // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 数据输出
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];  // 内存阵列

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en) begin
            if (we_a) ram[addr_a] <= din_a;  // 写入数据
            if (we_b) ram[addr_b] <= din_b;  // 写入数据
            dout_a <= ram[addr_a];           // 输出数据
            dout_b <= ram[addr_b];           // 输出数据
        end
    end
endmodule
