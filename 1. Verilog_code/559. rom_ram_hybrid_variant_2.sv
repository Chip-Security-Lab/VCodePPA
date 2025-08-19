//SystemVerilog
module rom_ram_hybrid #(parameter MODE=0)(
    input clk,
    input [7:0] addr,
    input [15:0] din,
    input rst,
    input valid_in,           // 输入有效信号
    output valid_out,         // 输出有效信号
    output [15:0] dout
);
    // 存储器定义
    reg [15:0] mem [0:255];
    
    // 流水线阶段寄存器
    reg [7:0] addr_pipeline;  // 地址流水线寄存器
    reg valid_pipeline;       // 有效信号流水线寄存器
    reg [15:0] dout_reg;      // 输出数据寄存器
    reg valid_out_reg;        // 输出有效信号寄存器

    // 内存读写信号 - 重定时后的前向信号
    wire [15:0] mem_read_data;
    
    // 初始化为0
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'h0000;
    end
    
    // 第一级流水线：地址注册和写入操作
    always @(posedge clk) begin
        if (rst) begin
            addr_pipeline <= 8'h00;
            valid_pipeline <= 1'b0;
            if (MODE == 1) begin
                for (i = 0; i < 256; i = i + 1)
                    mem[i] <= 16'h0000;
            end
        end else begin
            // 传递地址到流水线
            addr_pipeline <= addr;
            valid_pipeline <= valid_in;
            
            // 写入操作（如果MODE=1）
            if (MODE == 1 && valid_in) begin
                mem[addr] <= din;
            end
        end
    end
    
    // 组合逻辑：直接从内存读取数据
    assign mem_read_data = mem[addr_pipeline];
    
    // 输出寄存器：将组合逻辑结果注册到输出
    always @(posedge clk) begin
        if (rst) begin
            dout_reg <= 16'h0000;
            valid_out_reg <= 1'b0;
        end else begin
            dout_reg <= mem_read_data;
            valid_out_reg <= valid_pipeline;
        end
    end
    
    // 输出赋值
    assign dout = dout_reg;
    assign valid_out = valid_out_reg;
    
endmodule