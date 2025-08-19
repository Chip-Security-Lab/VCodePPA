module sync_single_port_ram #(
    parameter DATA_WIDTH = 8,   // 数据宽度
    parameter ADDR_WIDTH = 8    // 地址宽度
)(
    input wire clk,             // 时钟信号
    input wire rst,             // 复位信号
    input wire we,              // 写使能
    input wire [ADDR_WIDTH-1:0] addr, // 地址
    input wire [DATA_WIDTH-1:0] din,  // 输入数据
    output reg [DATA_WIDTH-1:0] dout  // 输出数据
);

    // 存储器数组
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (we) begin
            ram[addr] <= din;  // 写数据到存储器
        end else begin
            dout <= ram[addr]; // 读取数据
        end
    end
endmodule
