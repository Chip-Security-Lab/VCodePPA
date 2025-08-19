//SystemVerilog
module sync_dual_port_ram_with_priority #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire read_first,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_buf, addr_b_buf;
    reg [DATA_WIDTH-1:0] din_a_buf, din_b_buf;
    reg we_a_buf, we_b_buf;
    reg read_first_buf;
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;
    reg [DATA_WIDTH-1:0] next_dout_a, next_dout_b;
    reg [DATA_WIDTH-1:0] next_ram_data_a, next_ram_data_b;

    // 输入缓冲寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_buf <= 0;
            addr_b_buf <= 0;
            din_a_buf <= 0;
            din_b_buf <= 0;
            we_a_buf <= 0;
            we_b_buf <= 0;
            read_first_buf <= 0;
        end else begin
            addr_a_buf <= addr_a;
            addr_b_buf <= addr_b;
            din_a_buf <= din_a;
            din_b_buf <= din_b;
            we_a_buf <= we_a;
            we_b_buf <= we_b;
            read_first_buf <= read_first;
        end
    end

    // RAM读取逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a <= 0;
            ram_data_b <= 0;
        end else begin
            ram_data_a <= ram[addr_a_buf];
            ram_data_b <= ram[addr_b_buf];
        end
    end

    // 写操作逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位时不需要写操作
        end else begin
            if (we_a_buf) ram[addr_a_buf] <= din_a_buf;
            if (we_b_buf) ram[addr_b_buf] <= din_b_buf;
        end
    end

    // 输出逻辑
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