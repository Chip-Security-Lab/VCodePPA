//SystemVerilog
module clk_gate_div #(parameter DIV=2) (
    input clk, en,
    output reg clk_out
);
    // 流水线寄存器定义
    reg en_stage1, en_stage2;
    reg [7:0] cnt_stage1, cnt_stage2;
    reg next_cnt_zero_stage1, next_cnt_zero_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线：输入处理与计数逻辑
    always @(posedge clk) begin
        // 输入处理
        en_stage1 <= en;
        valid_stage1 <= 1'b1; // 第一级流水线始终有效
        
        // 计数逻辑
        if(en_stage1) begin
            cnt_stage1 <= (cnt_stage2 == DIV-1) ? 8'd0 : cnt_stage2 + 8'd1;
            next_cnt_zero_stage1 <= (cnt_stage2 == DIV-2) || ((cnt_stage2 == DIV-1) && (DIV == 1));
        end else begin
            cnt_stage1 <= cnt_stage2;
            next_cnt_zero_stage1 <= next_cnt_zero_stage2;
        end
    end
    
    // 第二级流水线：中间状态保存
    always @(posedge clk) begin
        en_stage2 <= en_stage1;
        valid_stage2 <= valid_stage1;
        cnt_stage2 <= cnt_stage1;
        next_cnt_zero_stage2 <= next_cnt_zero_stage1;
    end
    
    // 第三级流水线：输出时钟生成
    always @(posedge clk) begin
        if(valid_stage2 && en_stage2 && next_cnt_zero_stage2) begin
            clk_out <= ~clk_out;
        end
    end

    // 初始化逻辑
    initial begin
        clk_out = 1'b0;
        cnt_stage1 = 8'd0;
        cnt_stage2 = 8'd0;
        next_cnt_zero_stage1 = 1'b0;
        next_cnt_zero_stage2 = 1'b0;
        valid_stage1 = 1'b0;
        valid_stage2 = 1'b0;
        en_stage1 = 1'b0;
        en_stage2 = 1'b0;
    end
endmodule