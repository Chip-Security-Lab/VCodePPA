//SystemVerilog
module delayed_read_sync_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] dout_delayed;
    reg [DATA_WIDTH-1:0] ram_data;
    reg [DATA_WIDTH-1:0] sum_result;
    reg carry;
    
    // 添加缓冲寄存器
    reg [ADDR_WIDTH-1:0] addr_buf;
    reg [DATA_WIDTH-1:0] din_buf;
    reg we_buf;
    reg [DATA_WIDTH-1:0] ram_data_buf;
    reg [DATA_WIDTH-1:0] sum_result_buf;
    reg carry_buf;

    // 第一级缓冲
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_buf <= 0;
            din_buf <= 0;
            we_buf <= 0;
        end else begin
            addr_buf <= addr;
            din_buf <= din;
            we_buf <= we;
        end
    end

    // 第二级缓冲和RAM操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data <= 0;
            ram_data_buf <= 0;
        end else begin
            if (we_buf) begin
                ram[addr_buf] <= din_buf;
            end
            ram_data <= ram[addr_buf];
            ram_data_buf <= ram_data;
        end
    end

    // 第三级缓冲和计算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_result <= 0;
            carry <= 0;
            sum_result_buf <= 0;
            carry_buf <= 0;
        end else begin
            {carry, sum_result} = ram_data_buf + (~din_buf + 1'b1);
            {carry_buf, sum_result_buf} = {carry, sum_result};
        end
    end

    // 第四级缓冲和输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_delayed <= 0;
            dout <= 0;
        end else begin
            dout_delayed <= sum_result_buf;
            dout <= dout_delayed;
        end
    end

endmodule