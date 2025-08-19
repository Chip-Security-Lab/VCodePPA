//SystemVerilog
module sync_dual_port_ram_with_output_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                            // 时钟信号
    input wire rst,                            // 复位信号
    input wire we_a, we_b,                     // 写使能信号
    input wire oe_a, oe_b,                     // 输出使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 数据输出
);

    // 使用二维数组表示RAM，提高可读性
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 合并控制信号寄存器，减少寄存器数量
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg [3:0] ctrl_reg; // {we_a, we_b, oe_a, oe_b}
    
    // 写优先逻辑
    wire write_collision = we_a && we_b && (addr_a == addr_b);
    wire [DATA_WIDTH-1:0] write_data = write_collision ? din_a : 
                                      (we_a ? din_a : din_b);
    wire [ADDR_WIDTH-1:0] write_addr = write_collision ? addr_a : 
                                      (we_a ? addr_a : addr_b);
    wire write_enable = we_a || we_b;
    
    // 读逻辑
    wire [DATA_WIDTH-1:0] read_data_a = (addr_a == write_addr && write_enable) ? 
                                        write_data : ram[addr_a];
    wire [DATA_WIDTH-1:0] read_data_b = (addr_b == write_addr && write_enable) ? 
                                        write_data : ram[addr_b];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            din_a_reg <= 0;
            din_b_reg <= 0;
            ctrl_reg <= 4'b0;
        end else begin
            // 寄存器输入信号
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
            ctrl_reg <= {we_a, we_b, oe_a, oe_b};
            
            // 写操作
            if (write_enable) begin
                ram[write_addr] <= write_data;
            end
            
            // 读操作
            if (ctrl_reg[2]) dout_a <= read_data_a; // oe_a
            if (ctrl_reg[3]) dout_b <= read_data_b; // oe_b
        end
    end
endmodule