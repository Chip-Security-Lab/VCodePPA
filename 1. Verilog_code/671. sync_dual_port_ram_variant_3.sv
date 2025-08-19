//SystemVerilog
module sync_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg we_a_reg, we_b_reg;
    
    // 缓冲寄存器
    reg [DATA_WIDTH-1:0] ram_data_a_reg, ram_data_b_reg;
    reg [ADDR_WIDTH-1:0] addr_a_buf, addr_b_buf;
    reg we_a_buf, we_b_buf;

    // 输入寄存器级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_reg <= 0;
            din_b_reg <= 0;
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            we_a_reg <= 0;
            we_b_reg <= 0;
            addr_a_buf <= 0;
            addr_b_buf <= 0;
            we_a_buf <= 0;
            we_b_buf <= 0;
        end else begin
            din_a_reg <= din_a;
            din_b_reg <= din_b;
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            addr_a_buf <= addr_a_reg;
            addr_b_buf <= addr_b_reg;
            we_a_buf <= we_a_reg;
            we_b_buf <= we_b_reg;
        end
    end

    // 内存访问级
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_reg <= 0;
            ram_data_b_reg <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (we_a_buf) ram[addr_a_buf] <= din_a_reg;
            if (we_b_buf) ram[addr_b_buf] <= din_b_reg;
            ram_data_a_reg <= ram[addr_a_buf];
            ram_data_b_reg <= ram[addr_b_buf];
            dout_a <= ram_data_a_reg;
            dout_b <= ram_data_b_reg;
        end
    end
endmodule