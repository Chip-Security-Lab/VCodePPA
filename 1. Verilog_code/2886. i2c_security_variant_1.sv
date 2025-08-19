//SystemVerilog
module i2c_security #(
    parameter PARITY_EN = 1,
    parameter CMD_WHITELIST = 0
)(
    input  wire clk,
    input  wire rst_sync_n,
    inout  wire sda,
    inout  wire scl, 
    output reg  parity_error,
    output reg  cmd_blocked
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // 奇偶校验+命令过滤
    reg [7:0] cmd_history;
    
    // 白名单命令
    localparam [7:0] CMD_A0 = 8'hA0;
    localparam [7:0] CMD_B4 = 8'hB4;
    localparam [7:0] CMD_C2 = 8'hC2;
    
    // 第一级流水线: 输入采样
    reg sda_stage1, scl_stage1;
    reg [2:0] bit_counter_stage1;
    reg [7:0] shift_reg_stage1;
    reg byte_complete_stage1;
    
    // 第二级流水线: 字节组装
    reg [7:0] shift_reg_stage2;
    reg byte_complete_stage2;
    reg parity_check_en_stage2;
    reg cmd_check_en_stage2;
    
    // 第三级流水线: 校验准备
    reg [7:0] shift_reg_stage3;
    reg byte_complete_stage3;
    reg parity_check_en_stage3;
    reg cmd_check_en_stage3;
    reg cmd_is_whitelist_stage3;
    reg calc_parity_stage3;
    
    // 第四级流水线: 校验执行
    reg parity_bit_stage4;
    reg sda_stage4;
    
    // 第一级流水线: 输入采样
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            sda_stage1 <= 1'b0;
            scl_stage1 <= 1'b0;
            bit_counter_stage1 <= 3'b000;
            shift_reg_stage1 <= 8'h0;
            byte_complete_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // 输入采样
            sda_stage1 <= sda;
            scl_stage1 <= scl;
            valid_stage1 <= 1'b1;
            byte_complete_stage1 <= 1'b0; // 默认值
            
            // 接收I2C数据
            if (scl_stage1) begin
                shift_reg_stage1 <= {shift_reg_stage1[6:0], sda_stage1};
                bit_counter_stage1 <= bit_counter_stage1 + 1'b1;
                
                // 完成一个字节
                if (bit_counter_stage1 == 3'b111) begin
                    byte_complete_stage1 <= 1'b1;
                    bit_counter_stage1 <= 3'b000;
                end
            end
        end
    end
    
    // 第二级流水线: 字节组装和使能信号生成
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg_stage2 <= 8'h0;
            byte_complete_stage2 <= 1'b0;
            parity_check_en_stage2 <= 1'b0;
            cmd_check_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            shift_reg_stage2 <= shift_reg_stage1;
            byte_complete_stage2 <= byte_complete_stage1;
            valid_stage2 <= valid_stage1;
            
            // 使能信号流水线化
            parity_check_en_stage2 <= byte_complete_stage1 && PARITY_EN;
            cmd_check_en_stage2 <= byte_complete_stage1 && CMD_WHITELIST;
        end
    end
    
    // 第三级流水线: 校验准备
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg_stage3 <= 8'h0;
            byte_complete_stage3 <= 1'b0;
            parity_check_en_stage3 <= 1'b0;
            cmd_check_en_stage3 <= 1'b0;
            cmd_is_whitelist_stage3 <= 1'b0;
            calc_parity_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            sda_stage4 <= 1'b0;
        end else if (valid_stage2) begin
            shift_reg_stage3 <= shift_reg_stage2;
            byte_complete_stage3 <= byte_complete_stage2;
            parity_check_en_stage3 <= parity_check_en_stage2;
            cmd_check_en_stage3 <= cmd_check_en_stage2;
            valid_stage3 <= valid_stage2;
            sda_stage4 <= sda_stage1; // 前递SDA信号到第四级，用于奇偶校验
            
            // 预计算奇偶校验位
            if (byte_complete_stage2) begin
                calc_parity_stage3 <= ^shift_reg_stage2;
            end
            
            // 预计算白名单校验
            cmd_is_whitelist_stage3 <= (shift_reg_stage2 == CMD_A0) || 
                                       (shift_reg_stage2 == CMD_B4) || 
                                       (shift_reg_stage2 == CMD_C2);
        end
    end
    
    // 第四级流水线: 校验执行
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_history <= 8'h0;
            parity_bit_stage4 <= 1'b0;
            parity_error <= 1'b0;
            cmd_blocked <= 1'b0;
            valid_stage4 <= 1'b0;
        end else if (valid_stage3) begin
            valid_stage4 <= valid_stage3;
            
            // 更新命令历史
            if (byte_complete_stage3) begin
                cmd_history <= shift_reg_stage3;
                parity_bit_stage4 <= calc_parity_stage3;
            end
            
            // 奇偶校验执行
            if (parity_check_en_stage3) begin
                if (calc_parity_stage3 != sda_stage4) begin
                    parity_error <= 1'b1;
                end else begin
                    parity_error <= 1'b0;
                end
            end
            
            // 命令白名单过滤执行
            if (cmd_check_en_stage3) begin
                if (cmd_is_whitelist_stage3) begin
                    cmd_blocked <= 1'b0; // 白名单命令放行
                end else begin
                    cmd_blocked <= 1'b1; // 阻止非白名单命令
                end
            end
        end
    end
endmodule