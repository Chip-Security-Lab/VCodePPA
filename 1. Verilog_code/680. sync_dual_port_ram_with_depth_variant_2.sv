//SystemVerilog
module sync_dual_port_ram_with_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    reg [DATA_WIDTH-1:0] lut [0:255];  // 8位查找表

    // 初始化查找表
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut[i] = i;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (we_a) begin
                ram[addr_a] <= lut[din_a];  // 使用查找表写入
            end
            if (we_b) begin
                ram[addr_b] <= lut[din_b];  // 使用查找表写入
            end
            dout_a <= lut[ram[addr_a]];     // 使用查找表读取
            dout_b <= lut[ram[addr_b]];     // 使用查找表读取
        end
    end
endmodule