module sync_single_port_ram_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256   // 可配置存储器深度
)(
    input wire clk,
    input wire rst,
    input wire we,               // 写使能
    input wire [ADDR_WIDTH-1:0] addr, // 地址
    input wire [DATA_WIDTH-1:0] din,  // 数据输入
    output reg [DATA_WIDTH-1:0] dout  // 数据输出
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];  // 可配置深度

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (we) begin
            ram[addr] <= din;  // 写数据
        end
        dout <= ram[addr];  // 读取数据
    end
endmodule
