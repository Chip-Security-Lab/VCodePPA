//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: i2c_security
// Description: I2C security module with pipelined critical paths
///////////////////////////////////////////////////////////////////////////////
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
    // 寄存器定义
    reg [7:0] cmd_history;
    reg parity_bit;
    reg [7:0] shift_reg;
    
    // 流水线寄存器
    reg [7:0] shift_reg_pipe;
    reg byte_complete;
    reg byte_complete_pipe;
    reg parity_check_result;
    reg [7:0] cmd_whitelist_match;
    
    // 白名单命令
    localparam [7:0] CMD_A0 = 8'hA0;
    localparam [7:0] CMD_B4 = 8'hB4;
    localparam [7:0] CMD_C2 = 8'hC2;
    
    //-------------------------------------------------------------------------
    // 第一级流水线 - I2C 数据接收
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h0;
            byte_complete <= 1'b0;
        end else begin
            if (scl) begin // SCL上升沿
                shift_reg <= {shift_reg[6:0], sda};
                
                // 完成一个字节检测
                byte_complete <= &shift_reg[2:0];
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // 第一级流水线 - 流水线寄存器更新
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg_pipe <= 8'h0;
            byte_complete_pipe <= 1'b0;
        end else begin
            shift_reg_pipe <= shift_reg;
            byte_complete_pipe <= byte_complete;
        end
    end
    
    //-------------------------------------------------------------------------
    // 第二级流水线 - 命令历史记录
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_history <= 8'h0;
        end else begin
            if (byte_complete_pipe) begin
                cmd_history <= shift_reg_pipe;
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // 第二级流水线 - 奇偶校验计算
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            parity_bit <= 1'b0;
            parity_check_result <= 1'b0;
        end else begin
            if (byte_complete_pipe && PARITY_EN) begin
                parity_bit <= ^shift_reg_pipe;
                parity_check_result <= (parity_bit == sda);
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // 第二级流水线 - 命令白名单匹配预计算
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_whitelist_match <= 8'h0;
        end else begin
            if (byte_complete_pipe && CMD_WHITELIST) begin
                cmd_whitelist_match[0] <= (shift_reg_pipe == CMD_A0);
                cmd_whitelist_match[1] <= (shift_reg_pipe == CMD_B4);
                cmd_whitelist_match[2] <= (shift_reg_pipe == CMD_C2);
                cmd_whitelist_match[7:3] <= 5'b0; // 确保未使用位置为0
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // 第三级流水线 - 奇偶校验错误输出
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            parity_error <= 1'b0;
        end else begin
            if (PARITY_EN && byte_complete_pipe) begin
                parity_error <= !parity_check_result;
            end
        end
    end
    
    //-------------------------------------------------------------------------
    // 第三级流水线 - 命令白名单过滤输出
    //-------------------------------------------------------------------------
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_blocked <= 1'b0;
        end else begin
            if (CMD_WHITELIST && byte_complete_pipe) begin
                // 默认阻止，只有在匹配任一白名单命令时才放行
                cmd_blocked <= !(|cmd_whitelist_match[2:0]);
            end
        end
    end
    
endmodule