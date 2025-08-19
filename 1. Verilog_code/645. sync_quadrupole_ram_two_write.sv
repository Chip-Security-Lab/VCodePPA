module sync_quadrupole_ram_two_write #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d, // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d, // 地址
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,   // 输入数据
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d  // 输出数据
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            dout_c <= 0;
            dout_d <= 0;
        end else begin
            if (we_a) ram[addr_a] <= din_a;
            if (we_b) ram[addr_b] <= din_b;
            if (we_c) ram[addr_c] <= din_c;
            if (we_d) ram[addr_d] <= din_d;

            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
            dout_c <= ram[addr_c];
            dout_d <= ram[addr_d];
        end
    end
endmodule
