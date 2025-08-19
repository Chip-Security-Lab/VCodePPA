//SystemVerilog
module wave1_square_basic #(
    parameter PERIOD = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  wave_out
);
    // 定义流水线级数
    localparam PIPELINE_STAGES = 3;
    
    // 计数器和比较结果流水线寄存器
    reg [$clog2(PERIOD)-1:0] cnt;
    reg [$clog2(PERIOD)-1:0] cnt_stage1;
    reg [$clog2(PERIOD)-1:0] cnt_stage2;
    
    // 有效信号流水线控制
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 比较结果流水线寄存器
    reg cnt_eq_period_minus1_stage1;
    reg cnt_eq_period_minus1_stage2;
    
    // 输出信号流水线寄存器
    reg wave_out_next;
    
    // 流水线阶段1: 计数器更新和比较
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            cnt_stage1 <= 0;
            valid_stage1 <= 0;
            cnt_eq_period_minus1_stage1 <= 0;
        end else begin
            valid_stage1 <= 1'b1; // 初始阶段总是有效
            cnt_stage1 <= cnt;
            
            // 比较逻辑放在第一级流水线
            cnt_eq_period_minus1_stage1 <= (cnt == PERIOD-1);
            
            // 计数器更新逻辑
            if (cnt_eq_period_minus1_stage2 && valid_stage3) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
    
    // 流水线阶段2: 比较结果传递和输出计算准备
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_stage2 <= 0;
            valid_stage2 <= 0;
            cnt_eq_period_minus1_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            cnt_stage2 <= cnt_stage1;
            cnt_eq_period_minus1_stage2 <= cnt_eq_period_minus1_stage1;
        end
    end
    
    // 流水线阶段3: 输出更新控制
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_stage3 <= 0;
            wave_out_next <= 0;
            wave_out <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            // 计算下一个wave_out值
            if (valid_stage3 && cnt_eq_period_minus1_stage2) begin
                wave_out_next <= ~wave_out;
            end
            
            // 更新输出
            if (valid_stage3) begin
                if (cnt_eq_period_minus1_stage2) begin
                    wave_out <= wave_out_next;
                end
            end
        end
    end
endmodule