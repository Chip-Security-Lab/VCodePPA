module sync_dual_port_ram_rw #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,              // 写使能
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 输入数据
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 输出数据
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (we_a) ram[addr_a] <= din_a;
            if (we_b) ram[addr_b] <= din_b;
            dout_a <= ram[addr_a];
            dout_b <= ram[addr_b];
        end
    end
endmodule
