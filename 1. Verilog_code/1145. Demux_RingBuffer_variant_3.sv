//SystemVerilog
module Demux_RingBuffer #(parameter DW=8, N=8) (
    input wire clk,
    input wire wr_en,
    input wire [$clog2(N)-1:0] ptr,
    input wire [DW-1:0] data_in,
    output reg [N-1:0][DW-1:0] buffer
);
    // 分割关键路径的流水线寄存器
    reg [$clog2(N)-1:0] ptr_reg;
    reg [$clog2(N)-1:0] next_ptr_reg;
    reg wr_en_reg;
    reg [DW-1:0] data_in_reg;
    
    // 第一级流水线 - 记录输入信号和计算下一个指针
    always @(posedge clk) begin
        ptr_reg <= ptr;
        next_ptr_reg <= (ptr == N-1) ? {$clog2(N){1'b0}} : ptr + 1'b1;
        wr_en_reg <= wr_en;
        data_in_reg <= data_in;
    end
    
    // 第二级流水线 - 执行实际的缓冲区写入操作
    always @(posedge clk) begin
        if(wr_en_reg) begin
            buffer[ptr_reg] <= data_in_reg;
            buffer[next_ptr_reg] <= {DW{1'b0}}; // 使用位复制更高效地清零
        end
    end
endmodule