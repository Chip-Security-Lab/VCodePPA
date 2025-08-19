//SystemVerilog
module sync_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,                        // 时钟信号
    input wire rst,                        // 复位信号
    input wire en,                         // 使能信号
    input wire we_a, we_b,                 // 写使能信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址输入
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 数据输入
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 数据输出
);

    // 内存阵列
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 地址冲突检测
    wire addr_collision;
    assign addr_collision = (addr_a == addr_b) && (we_a || we_b);
    
    // 写优先级逻辑
    wire write_priority_a, write_priority_b;
    assign write_priority_a = we_a && (!we_b || addr_a != addr_b);
    assign write_priority_b = we_b && (!we_a || addr_a != addr_b);
    
    // 数据输入寄存器
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    
    // 地址寄存器
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;
    
    // 写使能寄存器
    reg we_a_reg, we_b_reg;
    
    // 地址和数据输入流水线
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_reg <= 0;
            addr_b_reg <= 0;
            we_a_reg <= 0;
            we_b_reg <= 0;
            din_a_reg <= 0;
            din_b_reg <= 0;
        end else if (en) begin
            addr_a_reg <= addr_a;
            addr_b_reg <= addr_b;
            we_a_reg <= we_a;
            we_b_reg <= we_b;
            din_a_reg <= din_a;
            din_b_reg <= din_b;
        end
    end
    
    // 内存访问流水线 - 优化写操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else if (en) begin
            // 写操作 - 处理地址冲突
            if (write_priority_a) begin
                ram[addr_a_reg] <= din_a_reg;
            end else if (write_priority_b) begin
                ram[addr_b_reg] <= din_b_reg;
            end
            
            // 读操作 - 直接输出，减少寄存器使用
            dout_a <= we_a_reg ? din_a_reg : ram[addr_a_reg];
            dout_b <= we_b_reg ? din_b_reg : ram[addr_b_reg];
        end
    end
    
endmodule