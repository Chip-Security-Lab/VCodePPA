module sync_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,               // 使能信号
    input wire we,               // 写使能
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (en) begin
            if (we) begin
                ram[addr] <= din;  // 写数据到存储器
            end
            dout <= ram[addr];  // 读取数据
        end
    end
endmodule
