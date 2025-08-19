//SystemVerilog
// 顶层模块
module inline_log_xnor (
    input  wire clk,      // 时钟输入用于流水线寄存器
    input  wire rst_n,    // 复位信号
    input  wire a,
    input  wire b,
    output wire out
);

    // 内部流水线信号
    (* dont_touch = "true" *) reg  stage1_a, stage1_b;
    (* dont_touch = "true" *) wire stage1_result;
    (* dont_touch = "true" *) reg  stage2_result;
    (* dont_touch = "true" *) reg  out_reg;
    
    // 多级流水线实现，减少每级的逻辑延迟
    // 第一级流水线寄存器 - 直接实现输入缓存，简化数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end

    // 比较逻辑 - 优化的XNOR实现，降低逻辑深度
    assign stage1_result = (stage1_a == stage1_b);

    // 中间流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_result;
        end
    end

    // 输出缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_reg <= 1'b0;
        end else begin
            out_reg <= stage2_result;
        end
    end

    // 输出赋值
    assign out = out_reg;

endmodule