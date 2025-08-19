//SystemVerilog
module sync_comb_filter #(
    parameter W = 12,
    parameter DELAY = 8
)(
    input clk, rst_n, enable,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    // 使用更高效的存储结构
    reg [W-1:0] delay_line [0:DELAY-1];
    
    // 动态计算延迟线索引，减少逻辑资源
    reg [$clog2(DELAY)-1:0] head;
    wire [$clog2(DELAY)-1:0] tail;
    
    // 使用组合逻辑计算tail指针，避免额外寄存器
    assign tail = (head == 0) ? DELAY-1 : head-1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            // 重置输出和头指针
            dout <= 0;
            head <= 0;
            // 使用for循环初始化，但综合会自动优化
            for (integer i = 0; i < DELAY; i = i + 1)
                delay_line[i] <= 0;
        end else if (enable) begin
            // 只更新当前head位置，避免整体移动
            delay_line[head] <= din;
            // 更新head指针
            head <= (head == DELAY-1) ? 0 : head + 1;
            // 计算滤波输出：当前输入减去最老的样本
            dout <= din - delay_line[tail];
        end
    end
endmodule