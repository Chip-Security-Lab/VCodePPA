module sync_single_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,                      // 写使能
    input wire [ADDR_WIDTH-1:0] addr,   // 地址
    input wire [DATA_WIDTH-1:0] din,    // 数据输入
    input wire [DATA_WIDTH/8-1:0] byte_en, // 字节使能
    output reg [DATA_WIDTH-1:0] dout    // 数据输出
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (we) begin
            // 根据字节使能进行部分写入
            for (i = 0; i < DATA_WIDTH / 8; i = i + 1) begin
                if (byte_en[i]) begin
                    ram[addr][i*8 +: 8] <= din[i*8 +: 8];
                end
            end
        end
        dout <= ram[addr];  // 读取数据
    end
endmodule