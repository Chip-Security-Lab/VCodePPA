module sync_priority_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,               // 写使能
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 输入数据
    output reg [DATA_WIDTH-1:0] dout     // 输出数据
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            if (we_a) begin
                ram[addr_a] <= din_a;  // 写数据
                dout <= ram[addr_a];   // 输出数据
            end else if (we_b) begin
                ram[addr_b] <= din_b;  // 写数据
                dout <= ram[addr_b];   // 输出数据
            end
        end
    end
endmodule
