//SystemVerilog
module WindowMax #(parameter W=8, MAX_WIN=5) (
    input clk,
    input rst,  // 添加复位信号
    input [3:0] win_size,
    input [W-1:0] din,
    output reg [W-1:0] max_val
);
    // 缓冲区寄存器
    reg [W-1:0] buffer [0:MAX_WIN-1];
    
    // 流水线寄存器
    reg [W-1:0] max_stage1 [0:(MAX_WIN/2)-1];  // 第一级最大值
    reg [W-1:0] max_stage2 [0:(MAX_WIN/4)];    // 第二级最大值
    reg [3:0] win_size_stage1, win_size_stage2;  // 流水线中的窗口大小
    
    integer i, j;
    
    always @(posedge clk) begin
        if (rst) begin
            // 复位所有寄存器
            for (i=0; i<MAX_WIN; i=i+1) buffer[i] <= 0;
            for (i=0; i<(MAX_WIN/2); i=i+1) max_stage1[i] <= 0;
            for (i=0; i<=(MAX_WIN/4); i=i+1) max_stage2[i] <= 0;
            win_size_stage1 <= 0;
            win_size_stage2 <= 0;
            max_val <= 0;
        end
        else begin
            // 阶段1: 移位缓冲区
            for(i=MAX_WIN-1; i>0; i=i-1)
                buffer[i] <= buffer[i-1];
            buffer[0] <= din;
            win_size_stage1 <= win_size;
            
            // 阶段2: 第一级比较 - 分组比较
            for (i=0; i<(MAX_WIN/2); i=i+1) begin
                if (2*i+1 < MAX_WIN) begin
                    // 对每组两个元素找最大值
                    if (2*i+1 < win_size_stage1 && buffer[2*i+1] > buffer[2*i] && 2*i < win_size_stage1)
                        max_stage1[i] <= buffer[2*i+1];
                    else if (2*i < win_size_stage1)
                        max_stage1[i] <= buffer[2*i];
                    else
                        max_stage1[i] <= 0;
                end else begin
                    // 处理奇数长度的情况
                    if (2*i < win_size_stage1)
                        max_stage1[i] <= buffer[2*i];
                    else
                        max_stage1[i] <= 0;
                end
            end
            win_size_stage2 <= win_size_stage1;
            
            // 阶段3: 第二级比较 - 继续合并比较结果
            for (i=0; i<=(MAX_WIN/4); i=i+1) begin
                if (2*i+1 < (MAX_WIN/2)) begin
                    if (max_stage1[2*i] > max_stage1[2*i+1])
                        max_stage2[i] <= max_stage1[2*i];
                    else
                        max_stage2[i] <= max_stage1[2*i+1];
                end else if (2*i < (MAX_WIN/2)) begin
                    max_stage2[i] <= max_stage1[2*i];
                end else begin
                    max_stage2[i] <= 0;
                end
            end
            
            // 阶段4: 最终比较 - 生成最终结果
            max_val <= max_stage2[0];
            for (i=1; i<=(MAX_WIN/4); i=i+1) begin
                if (max_stage2[i] > max_val)
                    max_val <= max_stage2[i];
            end
        end
    end
endmodule