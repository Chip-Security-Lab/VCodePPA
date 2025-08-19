//SystemVerilog
module low_power_bridge #(parameter DWIDTH=32) (
    input clk, rst_n, clk_en,
    input [DWIDTH-1:0] in_data,
    input in_valid, power_save,
    output reg in_ready,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready
);
    // 流水线阶段控制信号
    reg active_stage1, active_stage2;
    reg [DWIDTH-1:0] data_stage1;
    reg valid_stage1;
    
    // 高扇出信号缓冲
    reg [DWIDTH-1:0] buffered_data_stage1;
    reg buffered_valid_stage1;

    // 第一阶段：输入捕获和低功耗控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_stage1 <= 1;
            in_ready <= 1;
            valid_stage1 <= 0;
            data_stage1 <= 0;
            buffered_data_stage1 <= 0;
            buffered_valid_stage1 <= 0;
        end else if (clk_en) begin
            if (power_save && out_valid && out_ready) begin
                active_stage1 <= 0;  // 交易完成后进入低功耗
            end else if (!power_save) begin
                active_stage1 <= 1;  // 退出低功耗模式
            end
            
            // 输入捕获
            if (active_stage1) begin
                if (in_valid && in_ready) begin
                    data_stage1 <= in_data;
                    valid_stage1 <= 1;
                    in_ready <= 0;
                end else if (valid_stage1 && active_stage2 && !valid_stage2) begin
                    valid_stage1 <= 0;
                    in_ready <= 1;
                end
            end
        end
    end
    
    // 第二阶段：输出控制
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_stage2 <= 1;
            valid_stage2 <= 0;
            out_data <= 0;
            out_valid <= 0;
        end else if (clk_en) begin
            // 同步激活状态
            active_stage2 <= active_stage1;
            
            // 输出控制逻辑
            if (active_stage2) begin
                if (valid_stage1 && !valid_stage2) begin
                    buffered_data_stage1 <= data_stage1;  // 使用缓冲数据
                    buffered_valid_stage1 <= 1; // 标记有效
                    out_data <= buffered_data_stage1; // 输出数据
                    out_valid <= 1;
                    valid_stage2 <= 1;
                end else if (valid_stage2 && out_ready) begin
                    out_valid <= 0;
                    valid_stage2 <= 0;
                end
            end
        end
    end
endmodule