//SystemVerilog
module flagged_shift_reg #(parameter DEPTH = 8) (
    input wire clk, rst, push, pop,
    input wire data_in,
    output wire data_out,
    output wire empty, full
);
    // 流水线级对应的FIFO存储
    reg [DEPTH-1:0] fifo_stage1;
    reg [DEPTH-1:0] fifo_stage2;
    
    // 流水线计数器
    reg [$clog2(DEPTH):0] count_stage1;
    reg [$clog2(DEPTH):0] count_stage2;
    
    // 流水线控制信号
    reg push_valid_stage1, pop_valid_stage1;
    reg push_valid_stage2, pop_valid_stage2;
    
    // 阶段1: 输入处理和操作验证
    always @(posedge clk) begin
        if (rst) begin
            push_valid_stage1 <= 0;
            pop_valid_stage1 <= 0;
            count_stage1 <= 0;
            fifo_stage1 <= 0;
        end else begin
            // 验证操作是否有效
            push_valid_stage1 <= push && (count_stage2 < DEPTH);
            pop_valid_stage1 <= pop && (count_stage2 > 0);
            
            // 传递当前状态到第一阶段
            count_stage1 <= count_stage2;
            fifo_stage1 <= fifo_stage2;
        end
    end
    
    // 阶段2: 执行FIFO操作
    always @(posedge clk) begin
        if (rst) begin
            fifo_stage2 <= 0;
            count_stage2 <= 0;
            push_valid_stage2 <= 0;
            pop_valid_stage2 <= 0;
        end else begin
            push_valid_stage2 <= push_valid_stage1;
            pop_valid_stage2 <= pop_valid_stage1;
            
            if (push_valid_stage1 && !pop_valid_stage1) begin
                // 只有推入操作
                fifo_stage2 <= {fifo_stage1[DEPTH-2:0], data_in};
                count_stage2 <= count_stage1 + 1'b1;
            end else if (!push_valid_stage1 && pop_valid_stage1) begin
                // 只有弹出操作
                fifo_stage2 <= {1'b0, fifo_stage1[DEPTH-1:1]};
                count_stage2 <= count_stage1 - 1'b1;
            end else if (push_valid_stage1 && pop_valid_stage1) begin
                // 同时推入和弹出
                fifo_stage2 <= {fifo_stage1[DEPTH-2:0], data_in};
                count_stage2 <= count_stage1; // 计数保持不变
            end else begin
                // 无操作
                fifo_stage2 <= fifo_stage1;
                count_stage2 <= count_stage1;
            end
        end
    end
    
    // 输出赋值 - 从第二级流水线获取
    assign data_out = fifo_stage2[DEPTH-1];
    assign empty = (count_stage2 == 0);
    assign full = (count_stage2 == DEPTH);
    
endmodule