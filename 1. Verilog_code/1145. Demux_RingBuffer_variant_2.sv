//SystemVerilog
module Demux_RingBuffer #(parameter DW=8, N=8) (
    input clk, wr_en,
    input [$clog2(N)-1:0] ptr,
    input [DW-1:0] data_in,
    output reg [N-1:0][DW-1:0] buffer
);
    // 流水线寄存器声明
    reg [$clog2(N)-1:0] ptr_stage1, ptr_stage2;
    reg [DW-1:0] data_in_stage1, data_in_stage2;
    reg wr_en_stage1, wr_en_stage2;
    
    // 计算下一位置的补码实现 - 阶段1
    wire [$clog2(N)-1:0] n_minus_1;
    reg [$clog2(N)-1:0] next_ptr_stage1;
    
    // 计算 N-1 的值
    assign n_minus_1 = N-1;
    
    // 流水线阶段1 - 地址计算和数据寄存
    always @(posedge clk) begin
        // 流水线第一级 - 寄存输入信号
        ptr_stage1 <= ptr;
        data_in_stage1 <= data_in;
        wr_en_stage1 <= wr_en;
        
        // 计算下一个指针位置
        next_ptr_stage1 <= (ptr == n_minus_1) ? '0 : ptr + 1'b1;
    end
    
    // 流水线阶段2 - 继续传递控制和数据信号
    always @(posedge clk) begin
        // 流水线第二级 - 继续传递信号
        ptr_stage2 <= ptr_stage1;
        data_in_stage2 <= data_in_stage1;
        wr_en_stage2 <= wr_en_stage1;
    end
    
    // 流水线阶段3 - 执行内存写入操作
    reg [$clog2(N)-1:0] next_ptr_stage2;
    
    always @(posedge clk) begin
        // 传递下一个指针位置
        next_ptr_stage2 <= next_ptr_stage1;
        
        // 最终的内存写入操作
        if(wr_en_stage2) begin
            buffer[ptr_stage2] <= data_in_stage2;
            buffer[next_ptr_stage2] <= '0; // 清空下一位置
        end
    end
endmodule