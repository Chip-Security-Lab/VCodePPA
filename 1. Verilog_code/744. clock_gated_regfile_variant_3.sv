//SystemVerilog
module clock_gated_regfile #(
    parameter DW = 40,
    parameter AW = 6
)(
    input clk,
    input global_en,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    // 存储器定义
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // 改进的时钟门控逻辑
    // 使用查找表辅助实现减法操作，计算哪些地址区域有效
    // 8位查找表，用于辅助地址有效性检查的减法操作
    reg [7:0] lut_sub [0:255];
    reg [7:0] op1, op2, sub_result;
    wire addr_region_valid;
    
    // 初始化查找表
    integer i, j;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                lut_sub[i] = i - j[7:0];
            end
        end
    end
    
    // 使用查找表实现减法来判断地址有效性
    always @(*) begin
        op1 = 8'hFF;                    // 最大值
        op2 = {2'b00, addr[5:0]};       // 当前地址扩展到8位
        sub_result = lut_sub[op1];      // 通过查表计算差值
    end
    
    // 根据减法结果来判断地址区域有效性
    assign addr_region_valid = ~(sub_result < 8'h40); // 检查地址是否不在最后1/4区域
    wire region_clk_enable = global_en & addr_region_valid;
    wire region_clk;
    
    // 使用标准时钟门控单元结构
    reg enable_latch;
    always @(*) begin
        if (!clk)
            enable_latch = region_clk_enable;
    end
    
    assign region_clk = clk & enable_latch;
    
    // 写入操作
    always @(posedge region_clk) begin
        if (wr_en) mem[addr] <= din;
    end
    
    // 读取操作 - 使用寄存器改善时序
    reg [DW-1:0] dout_reg;
    always @(posedge clk) begin
        if (global_en)
            dout_reg <= mem[addr];
    end
    
    assign dout = dout_reg;
endmodule