//SystemVerilog
module pipelined_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in, pattern,
    output reg match_out
);
    // 移除了原来的data_reg和comp_result寄存器
    // 直接在输入阶段进行比较，减少了关键路径延迟
    
    // 添加了pattern_reg寄存器来存储pattern，以便可以在数据到来时立即比较
    reg [WIDTH-1:0] pattern_reg;
    
    // 创建多级流水线寄存器
    reg stage1_match;
    reg stage2_match;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_reg <= 0;
            stage1_match <= 0;
            stage2_match <= 0;
            match_out <= 0;
        end else begin
            // 存储pattern值
            pattern_reg <= pattern;
            
            // 将比较器移到数据输入阶段
            // 直接比较输入数据和存储的模式
            stage1_match <= (data_in == pattern_reg);
            
            // 流水线推进
            stage2_match <= stage1_match;
            match_out <= stage2_match;
        end
    end
endmodule