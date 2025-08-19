//SystemVerilog
module sync_dual_port_ram_with_subtraction #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                            // 时钟信号
    input wire rst,                            // 复位信号
    input wire we_a, we_b,                     // 写使能信号
    input wire oe_a, oe_b,                     // 输出使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,   // 减法操作数
    output reg [DATA_WIDTH-1:0] dout_a, dout_b, // 数据输出
    output reg [DATA_WIDTH-1:0] diff_a, diff_b  // 减法结果输出
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];  // 内存阵列
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;     // 地址流水线寄存器
    reg [DATA_WIDTH-1:0] ram_data_a, ram_data_b;     // RAM数据流水线寄存器
    reg oe_a_reg, oe_b_reg;                          // 输出使能流水线寄存器
    reg [DATA_WIDTH-1:0] sub_a_reg, sub_b_reg;       // 减法操作数流水线寄存器
    
    // 查找表 - 用于辅助减法运算
    reg [DATA_WIDTH-1:0] sub_lut [0:255];            // 减法查找表
    
    // 初始化查找表
    initial begin
        for (int i = 0; i < 256; i++) begin
            for (int j = 0; j < 256; j++) begin
                sub_lut[i] = i - j;
            end
        end
    end

    // 第一级流水线：地址、输出使能和减法操作数锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            oe_a_reg <= 0;
            oe_b_reg <= 0;
            sub_a_reg <= 0;
            sub_b_reg <= 0;
        end else begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            oe_a_reg <= oe_a;
            oe_b_reg <= oe_b;
            sub_a_reg <= sub_a;
            sub_b_reg <= sub_b;
        end
    end

    // 第二级流水线：RAM读写、输出数据锁存和减法运算
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a <= 0;
            ram_data_b <= 0;
            dout_a <= 0;
            dout_b <= 0;
            diff_a <= 0;
            diff_b <= 0;
        end else begin
            if (we_a) ram[addr_a_reg] <= din_a;
            if (we_b) ram[addr_b_reg] <= din_b;
            ram_data_a <= ram[addr_a_reg];
            ram_data_b <= ram[addr_b_reg];
            if (oe_a_reg) dout_a <= ram_data_a;
            if (oe_b_reg) dout_b <= ram_data_b;
            
            // 使用查找表辅助减法运算
            diff_a <= sub_lut[sub_a_reg];
            diff_b <= sub_lut[sub_b_reg];
        end
    end
endmodule