//SystemVerilog
module GatedDiv(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    // 内部信号定义
    reg [15:0] reciprocal;
    reg [15:0] x_reg, y_reg;
    reg y_zero;
    reg [31:0] mul_result;
    reg [3:0] state;
    reg computing;
    
    // 存储近似倒数的ROM
    reg [7:0] recip_table [0:255];
    
    // 初始化查找表
    initial begin
        // 填充倒数查找表 (1/x 的近似值，扩大到合适范围)
        // 这里使用 y 的高8位作为索引
        recip_table[0] = 8'hFF; // 特殊情况处理
        recip_table[1] = 8'hFF;
        recip_table[2] = 8'h80;
        recip_table[3] = 8'h55;
        recip_table[4] = 8'h40;
        recip_table[5] = 8'h33;
        recip_table[6] = 8'h2A;
        recip_table[7] = 8'h24;
        // ... 其他表项可以通过公式生成
        // 为简化示例，仅填充部分值，实际实现应填充完整表
        
        // 生成剩余表项 (示例逻辑)
        for (int i = 8; i < 256; i++) begin
            recip_table[i] = (255 * 256) / i; // 简化公式，实际中需要更精确计算
        end
    end
    
    // 牛顿-拉夫森法迭代改进近似倒数的精度
    always @(posedge clk) begin
        if (!en) begin
            computing <= 1'b0;
            state <= 4'd0;
        end 
        else if (!computing) begin
            // 开始新的计算
            x_reg <= x;
            y_reg <= y;
            y_zero <= (y == 16'd0);
            computing <= 1'b1;
            state <= 4'd1;
        end
        else begin
            case (state)
                4'd1: begin
                    // 加载初始近似倒数
                    if (y_zero) begin
                        q <= 16'hFFFF; // 除以零结果
                        computing <= 1'b0;
                        state <= 4'd0;
                    end
                    else begin
                        // 查表获取初始近似值
                        reciprocal <= {8'h0, recip_table[y_reg[15:8]]};
                        state <= 4'd2;
                    end
                end
                
                4'd2: begin
                    // 第一次牛顿迭代: r = r * (2 - y * r)
                    // 使用定点数表示法
                    mul_result <= y_reg * reciprocal;
                    state <= 4'd3;
                end
                
                4'd3: begin
                    // 计算 2 - y*r (根据定点数位宽调整)
                    mul_result <= (32'h20000 - mul_result[31:16]) * reciprocal;
                    state <= 4'd4;
                end
                
                4'd4: begin
                    // 更新近似倒数
                    reciprocal <= mul_result[23:8]; // 取合适位宽
                    state <= 4'd5;
                end
                
                4'd5: begin
                    // 第二次牛顿迭代，提高精度
                    mul_result <= y_reg * reciprocal;
                    state <= 4'd6;
                end
                
                4'd6: begin
                    mul_result <= (32'h20000 - mul_result[31:16]) * reciprocal;
                    state <= 4'd7;
                end
                
                4'd7: begin
                    reciprocal <= mul_result[23:8];
                    state <= 4'd8;
                end
                
                4'd8: begin
                    // 计算最终结果: q = x * (1/y)
                    mul_result <= x_reg * reciprocal;
                    state <= 4'd9;
                end
                
                4'd9: begin
                    // 输出结果
                    q <= mul_result[31:16]; // 取合适位宽
                    computing <= 1'b0;
                    state <= 4'd0;
                end
                
                default: begin
                    state <= 4'd0;
                    computing <= 1'b0;
                end
            endcase
        end
    end
endmodule