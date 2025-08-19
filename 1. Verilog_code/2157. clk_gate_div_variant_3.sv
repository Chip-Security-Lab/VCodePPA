//SystemVerilog
//////////////////////////////////////////////
// 模块名: clk_gate_div
// 功能: 可配置的时钟分频器 - 增加流水线深度优化版
//////////////////////////////////////////////
module clk_gate_div #(parameter DIV=2) (
    input  wire clk,     // 输入时钟
    input  wire en,      // 使能信号
    output reg  clk_out  // 分频输出时钟
);

    // 内部计数器，用于跟踪分频状态 - 拆分成多级流水线
    reg [7:0] cnt_stage1;
    reg [7:0] cnt_stage2;
    reg [7:0] cnt_final;
    
    // 流水线控制信号
    reg en_stage1, en_stage2;
    reg cnt_reset_stage1, cnt_reset_stage2, cnt_reset_final;
    reg toggle_clk_stage1, toggle_clk_stage2, toggle_clk_final;
    
    // 第一级流水线 - 计数器值计算和复位判断
    always @(posedge clk) begin
        en_stage1 <= en;
        if (en) begin
            cnt_reset_stage1 <= (cnt_final == DIV-1);
            cnt_stage1 <= cnt_reset_stage1 ? 8'd0 : cnt_final + 8'd1;
            toggle_clk_stage1 <= (cnt_final == DIV-1);
        end
    end
    
    // 第二级流水线 - 计数器值传递
    always @(posedge clk) begin
        en_stage2 <= en_stage1;
        cnt_stage2 <= cnt_stage1;
        cnt_reset_stage2 <= cnt_reset_stage1;
        toggle_clk_stage2 <= toggle_clk_stage1;
    end
    
    // 第三级流水线 - 最终计数器值和时钟切换判断
    always @(posedge clk) begin
        if (en_stage2) begin
            cnt_final <= cnt_stage2;
            cnt_reset_final <= cnt_reset_stage2;
            toggle_clk_final <= toggle_clk_stage2;
        end
    end
    
    // 时钟输出控制逻辑 - 根据流水线状态切换时钟
    always @(posedge clk) begin
        if (en_stage2) begin
            if (toggle_clk_final)
                clk_out <= ~clk_out;
        end
    end

endmodule