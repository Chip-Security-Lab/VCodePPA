//SystemVerilog
module OversampleFilter #(parameter OVERSAMPLE=3) (
    input clk,
    input din,
    output reg dout
);
    // 阶段1：采样缓冲区
    reg [OVERSAMPLE-1:0] sample_buf;
    
    // 阶段2：计数寄存器
    reg [3:0] ones_count;
    
    // 阶段3：表决结果
    wire majority_vote;
    
    // 采样阶段 - 移位寄存器
    always @(posedge clk) begin
        sample_buf <= {sample_buf[OVERSAMPLE-2:0], din};
    end
    
    // 计数阶段 - 使用独立组合逻辑结构
    reg [3:0] count_ones;
    integer i;
    
    always @(*) begin
        count_ones = 0;
        for (i = 0; i < OVERSAMPLE; i = i + 1) begin
            if (sample_buf[i]) 
                count_ones = count_ones + 1;
        end
    end
    
    // 计数结果寄存
    always @(posedge clk) begin
        ones_count <= count_ones;
    end
    
    // 表决阶段 - 使用组合逻辑确定多数表决
    assign majority_vote = (ones_count > (OVERSAMPLE/2));
    
    // 输出寄存器
    always @(posedge clk) begin
        dout <= majority_vote;
    end
endmodule