//SystemVerilog
module free_counter #(parameter MAX = 255) (
    input wire clk,
    output reg [7:0] count,
    output reg tc
);
    // 组合逻辑部分
    wire [7:0] next_count;
    wire next_tc;
    
    // 内部计数缓冲寄存器
    reg [7:0] count_buffer1, count_buffer2;
    
    // 计算下一个计数值的组合逻辑
    assign next_count = (count_buffer1 == MAX) ? 8'd0 : count_buffer1 + 1'b1;
    // 提前一个时钟周期计算tc信号，使用缓冲后的信号
    assign next_tc = (count_buffer2 == MAX - 2);
    
    // 时序逻辑部分
    always @(posedge clk) begin
        // 主计数寄存器更新
        count <= next_count;
        // 缓冲寄存器更新，分散扇出负载
        count_buffer1 <= count;
        count_buffer2 <= count;
        // 终止计数信号更新
        tc <= next_tc;
    end
endmodule