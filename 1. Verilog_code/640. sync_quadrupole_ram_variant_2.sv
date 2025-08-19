//SystemVerilog
module sync_quadrupole_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b, we_c, we_d,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c, addr_d,
    input wire [DATA_WIDTH-1:0] din_a, din_b, din_c, din_d,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, dout_c, dout_d
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg, addr_c_reg, addr_d_reg;
    reg [DATA_WIDTH-1:0] data_a_reg, data_b_reg, data_c_reg, data_d_reg;
    reg we_a_reg, we_b_reg, we_c_reg, we_d_reg;

    // 地址和写使能寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_reg, addr_b_reg, addr_c_reg, addr_d_reg} <= 0;
            {we_a_reg, we_b_reg, we_c_reg, we_d_reg} <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            addr_c_reg <= addr_c;
            addr_d_reg <= addr_d;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            we_c_reg <= we_c;
            we_d_reg <= we_d;
        end
    end

    // 数据输入寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {data_a_reg, data_b_reg, data_c_reg, data_d_reg} <= 0;
        end else begin
            data_a_reg <= din_a;
            data_b_reg <= din_b;
            data_c_reg <= din_c;
            data_d_reg <= din_d;
        end
    end

    // RAM写入操作
    always @(posedge clk) begin
        if (we_a_reg) ram[addr_a_reg] <= data_a_reg;
        if (we_b_reg) ram[addr_b_reg] <= data_b_reg;
        if (we_c_reg) ram[addr_c_reg] <= data_c_reg;
        if (we_d_reg) ram[addr_d_reg] <= data_d_reg;
    end

    // 数据输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {dout_a, dout_b, dout_c, dout_d} <= 0;
        end else begin
            dout_a <= ram[addr_a_reg];
            dout_b <= ram[addr_b_reg];
            dout_c <= ram[addr_c_reg];
            dout_d <= ram[addr_d_reg];
        end
    end

endmodule