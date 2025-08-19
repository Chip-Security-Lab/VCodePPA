module low_power_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,                  // 写使能
    input wire [ADDR_WIDTH-1:0] addr,  // 地址
    input wire [DATA_WIDTH-1:0] din,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout,  // 数据输出
    input wire low_power_mode        // 低功耗模式信号
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else if (!low_power_mode) begin
            if (we) ram[addr] <= din;  // 写数据
            dout <= ram[addr];         // 读取数据
        end
    end
endmodule
