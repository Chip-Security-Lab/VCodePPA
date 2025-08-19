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
    // 奇偶校验+命令过滤
    reg [7:0] cmd_history;
    reg parity_bit;
    reg [7:0] shift_reg;
    
    // 白名单命令
    localparam [7:0] CMD_A0 = 8'hA0;
    localparam [7:0] CMD_B4 = 8'hB4;
    localparam [7:0] CMD_C2 = 8'hC2;
    
    // I2C 移位寄存器更新
    always @(posedge clk or negedge rst_sync_n) begin
        if (!rst_sync_n) begin
            shift_reg <= 8'h0;
            cmd_history <= 8'h0;
            parity_bit <= 1'b0;
            parity_error <= 1'b0;
            cmd_blocked <= 1'b0;
        end else begin
            // 接收I2C数据
            if (scl) begin // SCL上升沿
                shift_reg <= {shift_reg[6:0], sda};
                
                // 完成一个字节
                if (&shift_reg[2:0]) begin
                    cmd_history <= shift_reg;
                    
                    // 奇偶校验生成
                    if (PARITY_EN) begin
                        parity_bit <= ^shift_reg;
                        if (parity_bit != sda) begin
                            parity_error <= 1'b1;
                        end else begin
                            parity_error <= 1'b0;
                        end
                    end
                    
                    // 命令白名单过滤
                    if (CMD_WHITELIST) begin
                        cmd_blocked <= 1'b1; // 默认阻止
                        
                        if (shift_reg == CMD_A0 || 
                            shift_reg == CMD_B4 || 
                            shift_reg == CMD_C2) begin
                            cmd_blocked <= 1'b0; // 白名单命令放行
                        end
                    end
                end
            end
        end
    end
endmodule