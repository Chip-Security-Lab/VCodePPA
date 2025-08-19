//SystemVerilog
// 顶层模块
module i2c_security #(
    parameter PARITY_EN = 1,
    parameter CMD_WHITELIST = 0
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl, 
    output parity_error,
    output cmd_blocked
);
    // 内部信号
    wire [7:0] shift_reg_out;
    wire byte_complete;
    wire parity_bit;
    
    // 实例化I2C接收器子模块
    i2c_receiver i2c_rx_inst (
        .clk(clk),
        .rst_sync_n(rst_sync_n),
        .sda(sda),
        .scl(scl),
        .shift_reg_out(shift_reg_out),
        .byte_complete(byte_complete)
    );
    
    // 实例化奇偶校验子模块
    parity_checker #(
        .PARITY_EN(PARITY_EN)
    ) parity_inst (
        .clk(clk),
        .rst_sync_n(rst_sync_n),
        .shift_reg(shift_reg_out),
        .sda(sda),
        .byte_complete(byte_complete),
        .parity_bit(parity_bit),
        .parity_error(parity_error)
    );
    
    // 实例化命令过滤器子模块
    cmd_filter #(
        .CMD_WHITELIST(CMD_WHITELIST)
    ) filter_inst (
        .clk(clk),
        .rst_sync_n(rst_sync_n),
        .shift_reg(shift_reg_out),
        .byte_complete(byte_complete),
        .cmd_blocked(cmd_blocked)
    );
    
endmodule

// I2C接收器子模块 - 处理I2C总线接收逻辑
module i2c_receiver (
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl,
    output reg [7:0] shift_reg_out,
    output reg byte_complete
);
    // 内部寄存器
    reg [7:0] shift_reg;
    reg [2:0] bit_pattern;
    reg [1:0] byte_complete_lut [0:7];
    
    // 初始化查找表
    initial begin
        byte_complete_lut[3'b111] = 2'b01; // 模式匹配，触发字节完成
        byte_complete_lut[3'b000] = 2'b00;
        byte_complete_lut[3'b001] = 2'b00;
        byte_complete_lut[3'b010] = 2'b00;
        byte_complete_lut[3'b011] = 2'b00;
        byte_complete_lut[3'b100] = 2'b00;
        byte_complete_lut[3'b101] = 2'b00;
        byte_complete_lut[3'b110] = 2'b00;
    end
    
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h0;
            shift_reg_out <= 8'h0;
            byte_complete <= 1'b0;
            bit_pattern <= 3'b000;
        end else begin
            byte_complete <= 1'b0; // 默认为低电平，只在字节完成时触发一个周期
            
            // 在SCL上升沿移位接收数据
            if (scl) begin
                shift_reg <= {shift_reg[6:0], sda};
                bit_pattern <= shift_reg[2:0];
                
                // 使用查找表检测字节完成
                if (byte_complete_lut[bit_pattern][0]) begin
                    shift_reg_out <= shift_reg; // 将完整字节输出
                    byte_complete <= 1'b1;      // 指示字节接收完成
                end
            end
        end
    end
endmodule

// 奇偶校验检查子模块 - 处理奇偶校验逻辑
module parity_checker #(
    parameter PARITY_EN = 1
)(
    input clk,
    input rst_sync_n,
    input [7:0] shift_reg,
    input sda,
    input byte_complete,
    output reg parity_bit,
    output reg parity_error
);
    reg [1:0] parity_lut [0:1];
    reg parity_index;
    
    // 初始化查找表
    initial begin
        parity_lut[0] = 2'b00; // parity_bit和sda不匹配 -> 错误
        parity_lut[1] = 2'b01; // parity_bit和sda匹配 -> 无错误
    end
    
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            parity_bit <= 1'b0;
            parity_error <= 1'b0;
            parity_index <= 1'b0;
        end else if (PARITY_EN && byte_complete) begin
            // 计算奇偶校验位
            parity_bit <= ^shift_reg;
            
            // 使用查找表检查奇偶校验错误
            parity_index <= (^shift_reg == sda);
            parity_error <= !parity_lut[parity_index][0];
        end
    end
endmodule

// 命令过滤器子模块 - 实现命令白名单过滤
module cmd_filter #(
    parameter CMD_WHITELIST = 0
)(
    input clk,
    input rst_sync_n,
    input [7:0] shift_reg,
    input byte_complete,
    output reg cmd_blocked
);
    // 命令历史记录
    reg [7:0] cmd_history;
    
    // 白名单查找表 - 8位地址，共256个条目
    reg [1:0] cmd_whitelist_lut [0:255];
    reg cmd_check_enable;
    
    // 初始化查找表
    initial begin
        integer i;
        // 默认所有命令都被阻止
        for (i = 0; i < 256; i = i + 1) begin
            cmd_whitelist_lut[i] = 2'b10; // 阻止命令
        end
        
        // 设置白名单命令
        cmd_whitelist_lut[8'hA0] = 2'b00; // 允许命令
        cmd_whitelist_lut[8'hB4] = 2'b00; // 允许命令
        cmd_whitelist_lut[8'hC2] = 2'b00; // 允许命令
    end
    
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            cmd_history <= 8'h0;
            cmd_blocked <= 1'b0;
            cmd_check_enable <= 1'b0;
        end else if (byte_complete) begin
            cmd_history <= shift_reg;
            cmd_check_enable <= CMD_WHITELIST;
            
            // 使用查找表实现白名单逻辑
            if (CMD_WHITELIST) begin
                cmd_blocked <= cmd_whitelist_lut[shift_reg][0];
            end else begin
                cmd_blocked <= 1'b0; // 如果不启用白名单，则不阻止任何命令
            end
        end
    end
endmodule