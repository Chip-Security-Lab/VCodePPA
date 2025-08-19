//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module i2c_digital_filter #(
    parameter FILTER_DEPTH = 4,
    parameter THRESHOLD = 3
)(
    input clk,
    input rst_n,
    input sda_raw,
    input scl_raw,
    output reg sda_filt,
    output reg scl_filt,
    output sda,
    output scl,
    input sda_oen,
    input scl_oen
);
    // 阶段1：输入捕获和历史记录更新
    reg [FILTER_DEPTH-1:0] sda_history;
    reg [FILTER_DEPTH-1:0] scl_history;
    reg sda_raw_stage1, scl_raw_stage1;
    reg sda_oen_stage1, scl_oen_stage1;
    reg valid_stage1;
    
    // 阶段2：计算求和
    reg [2:0] sda_sum_stage2; 
    reg [2:0] scl_sum_stage2;
    reg sda_oen_stage2, scl_oen_stage2;
    reg valid_stage2;
    
    // 阶段3：阈值比较
    reg sda_filt_stage3;
    reg scl_filt_stage3;
    reg sda_oen_stage3, scl_oen_stage3;
    reg valid_stage3;
    
    // 阶段4：输出生成
    reg sda_drive_stage4, scl_drive_stage4;
    reg sda_oen_stage4, scl_oen_stage4;
    reg valid_stage4;

    // 阶段1: 输入捕获和历史更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_history <= {FILTER_DEPTH{1'b1}};
            scl_history <= {FILTER_DEPTH{1'b1}};
            sda_raw_stage1 <= 1'b1;
            scl_raw_stage1 <= 1'b1;
            sda_oen_stage1 <= 1'b1;
            scl_oen_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            // 更新历史寄存器
            sda_history <= {sda_history[FILTER_DEPTH-2:0], sda_raw};
            scl_history <= {scl_history[FILTER_DEPTH-2:0], scl_raw};
            sda_raw_stage1 <= sda_raw;
            scl_raw_stage1 <= scl_raw;
            sda_oen_stage1 <= sda_oen;
            scl_oen_stage1 <= scl_oen;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段2: 求和计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_sum_stage2 <= FILTER_DEPTH;
            scl_sum_stage2 <= FILTER_DEPTH;
            sda_oen_stage2 <= 1'b1;
            scl_oen_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // 更新求和寄存器
                sda_sum_stage2 <= sda_sum_stage2 - sda_history[FILTER_DEPTH-1] + sda_raw_stage1;
                scl_sum_stage2 <= scl_sum_stage2 - scl_history[FILTER_DEPTH-1] + scl_raw_stage1;
                sda_oen_stage2 <= sda_oen_stage1;
                scl_oen_stage2 <= scl_oen_stage1;
                valid_stage2 <= valid_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 阶段3: 阈值比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_filt_stage3 <= 1'b1;
            scl_filt_stage3 <= 1'b1;
            sda_oen_stage3 <= 1'b1;
            scl_oen_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // 应用阈值过滤
                sda_filt_stage3 <= (sda_sum_stage2 >= THRESHOLD) ? 1'b1 : 1'b0;
                scl_filt_stage3 <= (scl_sum_stage2 >= THRESHOLD) ? 1'b1 : 1'b0;
                sda_oen_stage3 <= sda_oen_stage2;
                scl_oen_stage3 <= scl_oen_stage2;
                valid_stage3 <= valid_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // 阶段4: 输出生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_drive_stage4 <= 1'b1;
            scl_drive_stage4 <= 1'b1;
            sda_oen_stage4 <= 1'b1;
            scl_oen_stage4 <= 1'b1;
            valid_stage4 <= 1'b0;
            sda_filt <= 1'b1;
            scl_filt <= 1'b1;
        end else begin
            if (valid_stage3) begin
                sda_drive_stage4 <= sda_filt_stage3;
                scl_drive_stage4 <= scl_filt_stage3;
                sda_oen_stage4 <= sda_oen_stage3;
                scl_oen_stage4 <= scl_oen_stage3;
                valid_stage4 <= valid_stage3;
                
                // 更新输出寄存器
                sda_filt <= sda_filt_stage3;
                scl_filt <= scl_filt_stage3;
            end else begin
                valid_stage4 <= 1'b0;
            end
        end
    end
    
    // 总线控制逻辑 - 使用最终阶段的信号
    assign sda = sda_oen_stage4 ? 1'bz : sda_drive_stage4;
    assign scl = scl_oen_stage4 ? 1'bz : scl_drive_stage4;
    
endmodule