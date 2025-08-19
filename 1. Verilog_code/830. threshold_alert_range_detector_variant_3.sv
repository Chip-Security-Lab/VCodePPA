//SystemVerilog
//=========================================================
// 顶层模块 - 阈值告警范围检测器
//=========================================================
module threshold_alert_range_detector(
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output wire [1:0] alert_level // 00:normal, 01:warning, 10:critical
);
    // 内部连线
    wire in_normal_stage2, in_warning_stage2, in_critical_stage2;
    
    // 实例化范围检测子模块
    range_detector range_detector_inst (
        .clk(clk),
        .rst(rst),
        .sensor_data(sensor_data),
        .warning_low(warning_low),
        .warning_high(warning_high),
        .critical_low(critical_low),
        .critical_high(critical_high),
        .in_normal(in_normal_stage2),
        .in_warning(in_warning_stage2),
        .in_critical(in_critical_stage2)
    );
    
    // 实例化告警生成器子模块
    alert_generator alert_generator_inst (
        .clk(clk),
        .rst(rst),
        .in_warning(in_warning_stage2),
        .in_critical(in_critical_stage2),
        .alert_level(alert_level)
    );
    
endmodule

//=========================================================
// 子模块 - 范围检测器
//=========================================================
module range_detector (
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output reg in_normal,
    output reg in_warning,
    output reg in_critical
);
    // 阶段1 - 比较阶段
    reg [15:0] sensor_data_stage1;
    reg less_than_critical_low_stage1;
    reg less_than_warning_low_stage1;
    reg greater_than_warning_high_stage1;
    reg greater_than_critical_high_stage1;
    
    // 阶段2 - 中间计算阶段
    reg less_than_critical_low_stage2;
    reg less_than_warning_low_stage2;
    reg greater_than_warning_high_stage2;
    reg greater_than_critical_high_stage2;
    reg [15:0] sensor_data_stage2;
    
    // 阶段3 - 范围确定阶段
    reg normal_condition1_stage3;
    reg normal_condition2_stage3;
    reg warning_condition1_stage3;
    reg warning_condition2_stage3;
    
    // 阶段4 - 最终输出阶段
    reg in_normal_stage4;
    reg in_warning_stage4;
    reg in_critical_stage4;
    
    // 阶段1 - 比较阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sensor_data_stage1 <= 16'h0000;
            less_than_critical_low_stage1 <= 1'b0;
            less_than_warning_low_stage1 <= 1'b0;
            greater_than_warning_high_stage1 <= 1'b0;
            greater_than_critical_high_stage1 <= 1'b0;
        end else begin
            sensor_data_stage1 <= sensor_data;
            less_than_critical_low_stage1 <= (sensor_data < critical_low);
            less_than_warning_low_stage1 <= (sensor_data < warning_low);
            greater_than_warning_high_stage1 <= (sensor_data > warning_high);
            greater_than_critical_high_stage1 <= (sensor_data > critical_high);
        end
    end
    
    // 阶段2 - 中间计算阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            less_than_critical_low_stage2 <= 1'b0;
            less_than_warning_low_stage2 <= 1'b0;
            greater_than_warning_high_stage2 <= 1'b0;
            greater_than_critical_high_stage2 <= 1'b0;
            sensor_data_stage2 <= 16'h0000;
        end else begin
            less_than_critical_low_stage2 <= less_than_critical_low_stage1;
            less_than_warning_low_stage2 <= less_than_warning_low_stage1;
            greater_than_warning_high_stage2 <= greater_than_warning_high_stage1;
            greater_than_critical_high_stage2 <= greater_than_critical_high_stage1;
            sensor_data_stage2 <= sensor_data_stage1;
        end
    end
    
    // 阶段3 - 范围确定阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            normal_condition1_stage3 <= 1'b0;
            normal_condition2_stage3 <= 1'b0;
            warning_condition1_stage3 <= 1'b0;
            warning_condition2_stage3 <= 1'b0;
        end else begin
            // 拆分复杂条件运算成多个简单条件
            normal_condition1_stage3 <= ~less_than_warning_low_stage2;  // sensor_data >= warning_low
            normal_condition2_stage3 <= ~greater_than_warning_high_stage2; // sensor_data <= warning_high
            
            warning_condition1_stage3 <= ~less_than_critical_low_stage2 & less_than_warning_low_stage2;
            warning_condition2_stage3 <= greater_than_warning_high_stage2 & ~greater_than_critical_high_stage2;
        end
    end
    
    // 阶段4 - 最终输出阶段
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_normal_stage4 <= 1'b0;
            in_warning_stage4 <= 1'b0;
            in_critical_stage4 <= 1'b0;
        end else begin
            in_normal_stage4 <= normal_condition1_stage3 & normal_condition2_stage3;
            in_warning_stage4 <= warning_condition1_stage3 | warning_condition2_stage3;
            in_critical_stage4 <= less_than_critical_low_stage2 | greater_than_critical_high_stage2;
        end
    end
    
    // 最终输出赋值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_normal <= 1'b0;
            in_warning <= 1'b0;
            in_critical <= 1'b0;
        end else begin
            in_normal <= in_normal_stage4;
            in_warning <= in_warning_stage4;
            in_critical <= in_critical_stage4;
        end
    end
    
endmodule

//=========================================================
// 子模块 - 告警生成器
//=========================================================
module alert_generator (
    input wire clk, rst,
    input wire in_warning,
    input wire in_critical,
    output reg [1:0] alert_level
);
    // 增加滤波选项以避免瞬态告警
    parameter FILTER_ENABLE = 1;  // 启用告警滤波
    parameter FILTER_COUNT = 3;   // 连续检测到多少次才触发告警
    
    generate
        if (FILTER_ENABLE == 1) begin : filtered_alert
            // 带滤波的告警生成逻辑 - 增加流水线分级
            reg [1:0] count_warning_stage1 = 0;
            reg [1:0] count_critical_stage1 = 0;
            reg in_warning_stage1, in_critical_stage1;
            
            reg [1:0] count_warning_stage2 = 0;
            reg [1:0] count_critical_stage2 = 0;
            reg warning_threshold_met_stage2 = 0;
            reg critical_threshold_met_stage2 = 0;
            
            reg warning_stable_stage3 = 0;
            reg critical_stable_stage3 = 0;
            
            // 阶段1 - 计数器阶段
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    count_warning_stage1 <= 0;
                    count_critical_stage1 <= 0;
                    in_warning_stage1 <= 0;
                    in_critical_stage1 <= 0;
                end else begin
                    in_warning_stage1 <= in_warning;
                    in_critical_stage1 <= in_critical;
                    
                    // 警告计数器
                    if (in_warning)
                        count_warning_stage1 <= (count_warning_stage1 < FILTER_COUNT) ? count_warning_stage1 + 1'b1 : count_warning_stage1;
                    else
                        count_warning_stage1 <= 0;
                        
                    // 危险计数器
                    if (in_critical)
                        count_critical_stage1 <= (count_critical_stage1 < FILTER_COUNT) ? count_critical_stage1 + 1'b1 : count_critical_stage1;
                    else
                        count_critical_stage1 <= 0;
                end
            end
            
            // 阶段2 - 阈值检测阶段
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    count_warning_stage2 <= 0;
                    count_critical_stage2 <= 0;
                    warning_threshold_met_stage2 <= 0;
                    critical_threshold_met_stage2 <= 0;
                end else begin
                    count_warning_stage2 <= count_warning_stage1;
                    count_critical_stage2 <= count_critical_stage1;
                    
                    warning_threshold_met_stage2 <= (count_warning_stage1 == FILTER_COUNT);
                    critical_threshold_met_stage2 <= (count_critical_stage1 == FILTER_COUNT);
                end
            end
            
            // 阶段3 - 稳定信号生成阶段
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    warning_stable_stage3 <= 0;
                    critical_stable_stage3 <= 0;
                end else begin
                    warning_stable_stage3 <= warning_threshold_met_stage2;
                    critical_stable_stage3 <= critical_threshold_met_stage2;
                end
            end
            
            // 阶段4 - 告警生成阶段
            always @(posedge clk or posedge rst) begin
                if (rst) 
                    alert_level <= 2'b00;
                else 
                    alert_level <= {critical_stable_stage3, warning_stable_stage3};
            end
            
        end else begin : direct_alert
            // 直接告警生成逻辑 - 添加两级流水线
            reg in_warning_stage1, in_critical_stage1;
            reg in_warning_stage2, in_critical_stage2;
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    in_warning_stage1 <= 1'b0;
                    in_critical_stage1 <= 1'b0;
                end else begin
                    in_warning_stage1 <= in_warning;
                    in_critical_stage1 <= in_critical;
                end
            end
            
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    in_warning_stage2 <= 1'b0;
                    in_critical_stage2 <= 1'b0;
                end else begin
                    in_warning_stage2 <= in_warning_stage1;
                    in_critical_stage2 <= in_critical_stage1;
                end
            end
            
            always @(posedge clk or posedge rst) begin
                if (rst) 
                    alert_level <= 2'b00;
                else 
                    alert_level <= {in_critical_stage2, in_warning_stage2};
            end
        end
    endgenerate
    
endmodule