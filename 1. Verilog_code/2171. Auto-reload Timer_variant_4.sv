//SystemVerilog
module auto_reload_timer (
    input wire clk, rstn, en, reload_en,
    input wire [31:0] reload_val,
    output reg [31:0] count,
    output reg timeout
);
    // 增加流水线寄存器
    reg [31:0] reload_reg;
    reg [31:0] count_stage1, count_stage2;
    reg timeout_stage1, timeout_stage2;
    reg en_stage1, en_stage2;
    reg compare_result_stage1;
    
    // 分阶段处理逻辑
    // 阶段1: 寄存输入信号并执行部分计算
    always @(posedge clk) begin
        if (!rstn) begin
            en_stage1 <= 1'b0;
            count_stage1 <= 32'h0;
        end else begin
            en_stage1 <= en;
            count_stage1 <= count;
        end
    end
    
    // 阶段2: 比较逻辑
    always @(posedge clk) begin
        if (!rstn) begin
            compare_result_stage1 <= 1'b0;
            en_stage2 <= 1'b0;
            count_stage2 <= 32'h0;
        end else begin
            compare_result_stage1 <= (count_stage1 == reload_reg);
            en_stage2 <= en_stage1;
            count_stage2 <= count_stage1;
        end
    end
    
    // 阶段3: 最终计算和输出控制
    always @(posedge clk) begin
        if (!rstn) begin
            count <= 32'h0;
            timeout <= 1'b0;
            timeout_stage1 <= 1'b0;
            timeout_stage2 <= 1'b0;
        end else if (en_stage2) begin
            if (compare_result_stage1) begin
                count <= 32'h0;
                timeout_stage1 <= 1'b1;
            end else begin
                count <= count_stage2 + 32'h1;
                timeout_stage1 <= 1'b0;
            end
            timeout_stage2 <= timeout_stage1;
            timeout <= timeout_stage2;
        end
    end
    
    // 重载寄存器逻辑 - 保持相对独立的数据路径
    always @(posedge clk) begin
        if (!rstn) 
            reload_reg <= 32'hFFFFFFFF;
        else if (reload_en) 
            reload_reg <= reload_val;
    end
endmodule