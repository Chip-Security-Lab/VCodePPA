//SystemVerilog
module quad_clock_gen(
    input clock_in,
    input reset,
    output reg clock_0,
    output reg clock_90,
    output reg clock_180,
    output reg clock_270
);
    // 使用并行前缀加法器实现的2位计数器
    reg [1:0] phase_counter;
    
    // 并行前缀加法器所需的内部信号
    wire [1:0] next_counter;
    wire p0, g0, p1, g1; // 传播和生成信号
    wire c1;             // 进位信号
    
    // 计算传播和生成信号
    assign p0 = phase_counter[0];
    assign g0 = 0; // 对于加1操作，g0始终为0
    assign p1 = phase_counter[1];
    assign g1 = phase_counter[1] & phase_counter[0];
    
    // 计算进位信号 (并行前缀树)
    assign c1 = g0 | (p0 & 1'b1); // 1'b1是进位输入，对于加1操作始终为1
    
    // 计算下一个计数器值
    assign next_counter[0] = p0 ^ 1'b1;
    assign next_counter[1] = p1 ^ c1;
    
    // 预先计算时钟输出信号
    wire next_clock_0, next_clock_90, next_clock_180, next_clock_270;
    
    // 基于下一个计数器值预计算时钟输出
    assign next_clock_0 = (next_counter == 2'b00);
    assign next_clock_90 = (next_counter == 2'b01);
    assign next_clock_180 = (next_counter == 2'b10);
    assign next_clock_270 = (next_counter == 2'b11);
    
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            phase_counter <= 2'b00;
            clock_0 <= 1'b1;       // 重置时，clock_0应为高电平
            clock_90 <= 1'b0;
            clock_180 <= 1'b0;
            clock_270 <= 1'b0;
        end
        else begin
            phase_counter <= next_counter;
            clock_0 <= next_clock_0;
            clock_90 <= next_clock_90;
            clock_180 <= next_clock_180;
            clock_270 <= next_clock_270;
        end
    end
endmodule