//SystemVerilog
module sync_priority_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,              // 写使能
    input wire read_first,              // 读取优先级信号
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b, // 地址
    input wire [DATA_WIDTH-1:0] din_a, din_b,   // 输入数据
    output reg [DATA_WIDTH-1:0] dout_a, dout_b  // 输出数据
);

    // 内存数组定义
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // 缓存地址和数据信号，分割数据路径
    reg [ADDR_WIDTH-1:0] addr_a_r, addr_b_r;
    reg [DATA_WIDTH-1:0] din_a_r, din_b_r;
    reg we_a_r, we_b_r, read_first_r;
    
    // 预计算写使能条件，减少关键路径
    wire write_a_enable, write_b_enable;
    assign write_a_enable = we_a_r;
    assign write_b_enable = we_b_r;
    
    // 预计算读优先条件，减少关键路径
    wire read_priority;
    assign read_priority = read_first_r;
    
    // 地址和数据寄存 - 第一级流水线
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_r <= 0;
            addr_b_r <= 0;
            din_a_r <= 0;
            din_b_r <= 0;
            we_a_r <= 0;
            we_b_r <= 0;
            read_first_r <= 0;
        end else begin
            addr_a_r <= addr_a;
            addr_b_r <= addr_b;
            din_a_r <= din_a;
            din_b_r <= din_b;
            we_a_r <= we_a;
            we_b_r <= we_b;
            read_first_r <= read_first;
        end
    end
    
    // 内存写入和输出控制 - 第二级流水线
    // 合并读写操作到同一级流水线，减少关键路径
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            // 写入内存逻辑
            if (write_a_enable) ram[addr_a_r] <= din_a_r;
            if (write_b_enable) ram[addr_b_r] <= din_b_r;
            
            // 输出控制逻辑 - 使用条件运算符减少多路选择器深度
            dout_a <= read_priority ? ram[addr_a_r] : (write_a_enable ? din_a_r : ram[addr_a_r]);
            dout_b <= read_priority ? ram[addr_b_r] : (write_b_enable ? din_b_r : ram[addr_b_r]);
        end
    end
    
endmodule