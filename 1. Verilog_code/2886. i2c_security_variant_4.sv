//SystemVerilog
module i2c_security #(
    parameter PARITY_EN = 1,
    parameter CMD_WHITELIST = 0
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl, 
    output reg parity_error,
    output reg cmd_blocked
);
    // 流水线阶段信号定义
    reg [7:0] shift_reg;
    reg [7:0] cmd_history;
    reg data_valid_stage1;
    reg [7:0] cmd_stage2;
    reg data_valid_stage2;
    reg [3:0] parity_part1, parity_part2; // 拆分奇偶校验计算
    reg parity_bit_stage2, parity_bit_final;
    reg parity_calc_stage2, parity_calculated;
    reg sda_captured; // 捕获SDA值以减少输入路径延迟
    
    // 白名单命令
    localparam [7:0] CMD_A0 = 8'hA0;
    localparam [7:0] CMD_B4 = 8'hB4;
    localparam [7:0] CMD_C2 = 8'hC2;
    
    // 命令匹配预计算逻辑 - 拆分复杂比较逻辑
    reg cmd_match_a0_stage2, cmd_match_b4_stage2, cmd_match_c2_stage2;
    reg cmd_match_final;
    
    // 流水线阶段1: I2C数据接收和字节检测
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h0;
            cmd_history <= 8'h0;
            data_valid_stage1 <= 1'b0;
            sda_captured <= 1'b0;
        end else begin
            data_valid_stage1 <= 1'b0; // 默认无效
            sda_captured <= sda; // 捕获SDA值减少输入路径延迟
            
            // 接收I2C数据
            if (scl) begin // SCL上升沿
                shift_reg <= {shift_reg[6:0], sda_captured};
                
                // 完成一个字节
                if (&shift_reg[2:0]) begin
                    cmd_history <= shift_reg;
                    data_valid_stage1 <= 1'b1; // 数据有效，传递到下一级
                end
            end
        end
    end
    
    // 流水线阶段2: 奇偶校验计算第一阶段和命令匹配预计算
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_stage2 <= 8'h0;
            data_valid_stage2 <= 1'b0;
            parity_part1 <= 4'h0;
            parity_part2 <= 4'h0;
            parity_calc_stage2 <= 1'b0;
            cmd_match_a0_stage2 <= 1'b0;
            cmd_match_b4_stage2 <= 1'b0;
            cmd_match_c2_stage2 <= 1'b0;
        end else begin
            data_valid_stage2 <= data_valid_stage1;
            
            if (data_valid_stage1) begin
                cmd_stage2 <= cmd_history;
                
                // 奇偶校验计算拆分 - 减少XOR链
                if (PARITY_EN) begin
                    parity_part1 <= cmd_history[3:0];
                    parity_part2 <= cmd_history[7:4];
                    parity_calc_stage2 <= 1'b1;
                end else begin
                    parity_calc_stage2 <= 1'b0;
                end
                
                // 预计算命令匹配 - 拆分复杂比较逻辑
                if (CMD_WHITELIST) begin
                    cmd_match_a0_stage2 <= (cmd_history == CMD_A0);
                    cmd_match_b4_stage2 <= (cmd_history == CMD_B4);
                    cmd_match_c2_stage2 <= (cmd_history == CMD_C2);
                end
            end else begin
                parity_calc_stage2 <= 1'b0;
                cmd_match_a0_stage2 <= 1'b0;
                cmd_match_b4_stage2 <= 1'b0;
                cmd_match_c2_stage2 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段3: 奇偶校验计算最终阶段和命令匹配最终结果
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            parity_bit_final <= 1'b0;
            parity_calculated <= 1'b0;
            parity_bit_stage2 <= 1'b0;
            cmd_match_final <= 1'b0;
        end else begin
            // 奇偶校验计算第二阶段
            if (parity_calc_stage2) begin
                // 分两步计算奇偶校验，减少XOR链长度
                parity_bit_stage2 <= ^parity_part1;
                parity_bit_final <= ^parity_part2;
                parity_calculated <= 1'b1;
            end else begin
                parity_calculated <= 1'b0;
            end
            
            // 计算最终奇偶校验结果
            if (parity_calculated) begin
                parity_bit_final <= parity_bit_stage2 ^ parity_bit_final;
            end
            
            // 命令匹配结果合并
            if (data_valid_stage2 && CMD_WHITELIST) begin
                cmd_match_final <= cmd_match_a0_stage2 || cmd_match_b4_stage2 || cmd_match_c2_stage2;
            end
        end
    end
    
    // 流水线阶段4: 校验检查和命令过滤最终输出
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            parity_error <= 1'b0;
            cmd_blocked <= 1'b0;
        end else begin
            // 奇偶校验检查
            if (data_valid_stage2 && parity_calculated) begin
                if (parity_bit_final != sda_captured) begin
                    parity_error <= 1'b1;
                end else begin
                    parity_error <= 1'b0;
                end
            end
            
            // 命令白名单过滤 - 使用预计算结果
            if (data_valid_stage2 && CMD_WHITELIST) begin
                cmd_blocked <= ~cmd_match_final; // 使用预计算结果
            end
        end
    end
endmodule