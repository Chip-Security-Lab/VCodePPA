module sync_ram_with_error_detection #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,                    // 写使能
    input wire [ADDR_WIDTH-1:0] addr, // 地址
    input wire [DATA_WIDTH-1:0] din,  // 数据输入
    output reg [DATA_WIDTH-1:0] dout, // 数据输出
    output reg error_flag            // 错误检测标志
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
            error_flag <= 0;
        end else begin
            if (we) begin
                ram[addr] <= din;  // 写数据
                error_flag <= 0;   // 重置错误标志
            end
            dout <= ram[addr];  // 读取数据
            if (ram[addr] !== dout) begin
                error_flag <= 1;  // 检测到错误
            end
        end
    end
endmodule
