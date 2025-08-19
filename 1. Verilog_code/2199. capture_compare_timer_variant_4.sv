//SystemVerilog
module capture_compare_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] compare_val,
    output reg compare_match,
    output reg [WIDTH-1:0] capture_val
);
    // 阶段1寄存器
    reg [WIDTH-1:0] counter;
    reg capture_trig_prev;
    reg capture_trig_stage1;
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] compare_val_stage1;

    // 阶段2寄存器 - 拆分后
    reg capture_trig_prev_stage2;
    reg capture_trig_stage2;
    reg [WIDTH-1:0] counter_stage2;
    reg [WIDTH-1:0] compare_val_stage2;
    
    // 阶段3寄存器 - 新增
    reg capture_detected_stage3;
    reg [WIDTH/2-1:0] compare_part1_stage3;
    reg [WIDTH/2-1:0] counter_part1_stage3;
    reg [WIDTH/2-1:0] compare_part2_stage3;
    reg [WIDTH/2-1:0] counter_part2_stage3;
    
    // 阶段4寄存器 - 新增
    reg capture_detected_stage4;
    reg compare_part1_match_stage4;
    reg compare_part2_match_stage4;
    reg [WIDTH-1:0] counter_stage4;
    
    // 阶段5寄存器 - 新增
    reg capture_detected_stage5;
    reg compare_detected_stage5;
    reg [WIDTH-1:0] counter_stage5;

    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;

    // 阶段1: 计数器增加和输入捕获
    always @(posedge clk) begin
        if (rst) begin
            counter <= {WIDTH{1'b0}};
            capture_trig_prev <= 1'b0;
            capture_trig_stage1 <= 1'b0;
            counter_stage1 <= {WIDTH{1'b0}};
            compare_val_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            // 计数器增加
            counter <= counter + 1'b1;
            
            // 传递到阶段1
            capture_trig_prev <= capture_trig;
            capture_trig_stage1 <= capture_trig;
            counter_stage1 <= counter;
            compare_val_stage1 <= compare_val;
            valid_stage1 <= 1'b1;
        end
    end

    // 阶段2: 信号前进
    always @(posedge clk) begin
        if (rst) begin
            capture_trig_prev_stage2 <= 1'b0;
            capture_trig_stage2 <= 1'b0;
            counter_stage2 <= {WIDTH{1'b0}};
            compare_val_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            capture_trig_prev_stage2 <= capture_trig_prev;
            capture_trig_stage2 <= capture_trig_stage1;
            counter_stage2 <= counter_stage1;
            compare_val_stage2 <= compare_val_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // 阶段3: 捕获检测和比较分解
    always @(posedge clk) begin
        if (rst) begin
            capture_detected_stage3 <= 1'b0;
            compare_part1_stage3 <= {(WIDTH/2){1'b0}};
            counter_part1_stage3 <= {(WIDTH/2){1'b0}};
            compare_part2_stage3 <= {(WIDTH/2){1'b0}};
            counter_part2_stage3 <= {(WIDTH/2){1'b0}};
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // 捕获检测
            capture_detected_stage3 <= (capture_trig_stage2 && !capture_trig_prev_stage2);
            
            // 将比较操作分解为两部分
            counter_part1_stage3 <= counter_stage2[WIDTH/2-1:0];
            counter_part2_stage3 <= counter_stage2[WIDTH-1:WIDTH/2];
            compare_part1_stage3 <= compare_val_stage2[WIDTH/2-1:0];
            compare_part2_stage3 <= compare_val_stage2[WIDTH-1:WIDTH/2];
            
            valid_stage3 <= valid_stage2;
        end
    end

    // 阶段4: 比较子部分和结果传递
    always @(posedge clk) begin
        if (rst) begin
            capture_detected_stage4 <= 1'b0;
            compare_part1_match_stage4 <= 1'b0;
            compare_part2_match_stage4 <= 1'b0;
            counter_stage4 <= {WIDTH{1'b0}};
            valid_stage4 <= 1'b0;
        end else if (valid_stage3) begin
            // 部分比较
            compare_part1_match_stage4 <= (counter_part1_stage3 == compare_part1_stage3);
            compare_part2_match_stage4 <= (counter_part2_stage3 == compare_part2_stage3);
            
            // 传递信号
            capture_detected_stage4 <= capture_detected_stage3;
            counter_stage4 <= {counter_part2_stage3, counter_part1_stage3};
            valid_stage4 <= valid_stage3;
        end
    end

    // 阶段5: 合并比较结果
    always @(posedge clk) begin
        if (rst) begin
            capture_detected_stage5 <= 1'b0;
            compare_detected_stage5 <= 1'b0;
            counter_stage5 <= {WIDTH{1'b0}};
            valid_stage5 <= 1'b0;
        end else if (valid_stage4) begin
            // 合并比较结果
            compare_detected_stage5 <= (compare_part1_match_stage4 && compare_part2_match_stage4);
            
            // 传递信号
            capture_detected_stage5 <= capture_detected_stage4;
            counter_stage5 <= counter_stage4;
            valid_stage5 <= valid_stage4;
        end
    end

    // 阶段6: 输出生成
    always @(posedge clk) begin
        if (rst) begin
            compare_match <= 1'b0;
            capture_val <= {WIDTH{1'b0}};
        end else if (valid_stage5) begin
            // 设置比较匹配输出
            compare_match <= compare_detected_stage5;
            
            // 更新捕获值
            if (capture_detected_stage5) begin
                capture_val <= counter_stage5;
            end
        end
    end
endmodule