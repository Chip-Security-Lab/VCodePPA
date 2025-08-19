//SystemVerilog
module async_dual_port_ram_with_control #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire control_signal_a, control_signal_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    reg control_a_reg, control_b_reg;
    reg write_enable_a, write_enable_b;

    // 合并控制信号和写使能，减少比较操作
    always @(posedge clk) begin
        write_enable_a <= control_signal_a & we_a;
        write_enable_b <= control_signal_b & we_b;
    end

    // 优化输入寄存器级，减少寄存器数量
    always @(posedge clk) begin
        if (write_enable_a) begin
            addr_a_reg <= addr_a;
            din_a_reg <= din_a;
        end
        if (write_enable_b) begin
            addr_b_reg <= addr_b;
            din_b_reg <= din_b;
        end
    end

    // 合并写操作，减少条件判断
    always @(posedge clk) begin
        if (write_enable_a) begin
            ram[addr_a] <= din_a;
        end
        if (write_enable_b) begin
            ram[addr_b] <= din_b;
        end
    end

    // 优化读操作，使用组合逻辑提高速度
    always @(posedge clk) begin
        dout_a <= ram[addr_a];
        dout_b <= ram[addr_b];
    end

endmodule