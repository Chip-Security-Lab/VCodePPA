//SystemVerilog
module DoubleBufferMatcher #(parameter WIDTH=8) (
    input clk,
    input sel_buf,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern0, pattern1,
    output reg match
);
    // 流水线数据寄存器
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] pattern0_reg, pattern1_reg;
    reg sel_buf_reg;

    // 中间比较结果寄存器
    reg match_0_reg, match_1_reg;
    
    // 合并所有具有相同时钟触发条件的always块
    always @(posedge clk) begin
        // 第一级：寄存输入数据和选择信号
        data_reg <= data;
        pattern0_reg <= pattern0;
        pattern1_reg <= pattern1;
        sel_buf_reg <= sel_buf;
        
        // 第三级：直接计算并寄存比较结果
        match_0_reg <= (data_reg == pattern0_reg);
        match_1_reg <= (data_reg == pattern1_reg);
        
        // 第四级：选择输出结果
        match <= sel_buf_reg ? match_1_reg : match_0_reg;
    end
endmodule