//SystemVerilog
module sync_dual_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire [DATA_WIDTH/8-1:0] byte_en_a, byte_en_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    integer i;

    // 端口A写操作
    always @(posedge clk) begin
        for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
            if (we_a && byte_en_a[i]) begin
                ram[addr_a][i*8 +: 8] <= din_a[i*8 +: 8];
            end
        end
    end

    // 端口B写操作
    always @(posedge clk) begin
        for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
            if (we_b && byte_en_b[i]) begin
                ram[addr_b][i*8 +: 8] <= din_b[i*8 +: 8];
            end
        end
    end

    // 端口A读操作
    always @(posedge clk) begin
        ram_data_a <= ram[addr_a];
    end

    // 端口B读操作
    always @(posedge clk) begin
        ram_data_b <= ram[addr_b];
    end

    // 输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram_data_a;
            dout_b <= ram_data_b;
        end
    end

endmodule