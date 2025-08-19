//SystemVerilog using IEEE 1364-2005
module jk_ff_async_reset_pipelined (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    input wire valid_in,  // 输入有效信号
    output wire valid_out, // 输出有效信号
    output reg q
);
    // 内部流水线寄存器
    reg stage1_j, stage1_k, stage1_q, stage1_valid;
    reg stage2_next_q, stage2_valid;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_j <= 1'b0;
            stage1_k <= 1'b0;
            stage1_q <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_j <= j;
            stage1_k <= k;
            stage1_q <= q;
            stage1_valid <= valid_in;
        end
    end
    
    // 第二级流水线：计算下一状态并寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_next_q <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            // 基于第一级寄存器的值计算下一状态
            if (stage1_j && stage1_k)
                stage2_next_q <= ~stage1_q;
            else if (stage1_j)
                stage2_next_q <= 1'b1;
            else if (stage1_k)
                stage2_next_q <= 1'b0;
            else
                stage2_next_q <= stage1_q;
                
            stage2_valid <= stage1_valid;
        end
    end
    
    // 第三级流水线：更新输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else if (stage2_valid)
            q <= stage2_next_q;
    end
    
    // 输出有效信号
    assign valid_out = stage2_valid;
    
endmodule