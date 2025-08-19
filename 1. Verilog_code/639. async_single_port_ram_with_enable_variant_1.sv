//SystemVerilog
module async_single_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                    // 时钟信号
    input wire [ADDR_WIDTH-1:0] addr,  // 地址输入
    input wire [DATA_WIDTH-1:0] din,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout,  // 数据输出
    input wire we,                     // 写使能
    input wire en                      // 使能信号
);

    // 内部信号定义
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] read_data;
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg write_enable;
    reg read_enable;

    // 地址和控制信号寄存
    always @(posedge clk) begin
        addr_reg <= addr;
        write_enable <= we & en;
        read_enable <= ~we & en;
    end

    // 写操作
    always @(posedge clk) begin
        if (write_enable) begin
            ram[addr_reg] <= din;
        end
    end

    // 读操作
    always @(posedge clk) begin
        if (read_enable) begin
            read_data <= ram[addr_reg];
        end
    end

    // 输出寄存器
    always @(posedge clk) begin
        dout <= read_data;
    end

endmodule