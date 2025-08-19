//SystemVerilog
module pl_reg_stall #(parameter W=4) (
    input clk, rst, load, stall,
    input [W-1:0] new_data,
    output reg [W-1:0] current_data
);
    // 内部信号定义
    reg [7:0] subtractor_a, subtractor_b;
    wire [7:0] diff;
    wire [7:0] borrow;
    
    // 为高扇出信号添加缓冲寄存器
    reg [7:0] subtractor_a_buf1, subtractor_a_buf2;
    reg [7:0] subtractor_b_buf1, subtractor_b_buf2;
    reg [7:0] diff_buf1, diff_buf2;
    reg [3:0] borrow_buf1, borrow_buf2;
    reg [3:0] borrow_buf3, borrow_buf4;
    
    // 更新寄存器缓冲区
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            subtractor_a_buf1 <= 8'b0;
            subtractor_a_buf2 <= 8'b0;
            subtractor_b_buf1 <= 8'b0;
            subtractor_b_buf2 <= 8'b0;
            diff_buf1 <= 8'b0;
            diff_buf2 <= 8'b0;
            borrow_buf1 <= 4'b0;
            borrow_buf2 <= 4'b0;
            borrow_buf3 <= 4'b0;
            borrow_buf4 <= 4'b0;
        end
        else begin
            // 更新缓冲寄存器
            subtractor_a_buf1 <= subtractor_a;
            subtractor_a_buf2 <= subtractor_a;
            subtractor_b_buf1 <= subtractor_b;
            subtractor_b_buf2 <= subtractor_b;
            diff_buf1 <= diff;
            diff_buf2 <= diff;
            borrow_buf1 <= borrow[3:0];
            borrow_buf2 <= borrow[3:0];
            borrow_buf3 <= borrow[7:4];
            borrow_buf4 <= borrow[7:4];
        end
    end
    
    // 分层实现借位逻辑以减少扇出负载
    wire b1, b2, b3, b4, b5, b6, b7;
    
    // 第一级借位计算，使用缓冲寄存器减少扇出
    assign borrow[0] = 1'b0;
    assign b1 = subtractor_a_buf1[0] < subtractor_b_buf1[0] ? 1'b1 : 1'b0;
    assign b2 = (subtractor_a_buf1[1] < subtractor_b_buf1[1]) || 
                ((subtractor_a_buf1[1] == subtractor_b_buf1[1]) && b1) ? 1'b1 : 1'b0;
    assign b3 = (subtractor_a_buf1[2] < subtractor_b_buf1[2]) || 
                ((subtractor_a_buf1[2] == subtractor_b_buf1[2]) && b2) ? 1'b1 : 1'b0;
    assign b4 = (subtractor_a_buf1[3] < subtractor_b_buf1[3]) || 
                ((subtractor_a_buf1[3] == subtractor_b_buf1[3]) && b3) ? 1'b1 : 1'b0;
    
    // 寄存内部借位，减少扇出
    reg b1_reg, b2_reg, b3_reg, b4_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            b1_reg <= 1'b0;
            b2_reg <= 1'b0;
            b3_reg <= 1'b0;
            b4_reg <= 1'b0;
        end
        else begin
            b1_reg <= b1;
            b2_reg <= b2;
            b3_reg <= b3;
            b4_reg <= b4;
        end
    end
    
    // 使用寄存的借位信号处理下半部分
    assign b5 = (subtractor_a_buf2[4] < subtractor_b_buf2[4]) || 
                ((subtractor_a_buf2[4] == subtractor_b_buf2[4]) && b4_reg) ? 1'b1 : 1'b0;
    assign b6 = (subtractor_a_buf2[5] < subtractor_b_buf2[5]) || 
                ((subtractor_a_buf2[5] == subtractor_b_buf2[5]) && b5) ? 1'b1 : 1'b0;
    assign b7 = (subtractor_a_buf2[6] < subtractor_b_buf2[6]) || 
                ((subtractor_a_buf2[6] == subtractor_b_buf2[6]) && b6) ? 1'b1 : 1'b0;
    
    // 将所有借位连接到borrow总线
    assign borrow[1] = b1;
    assign borrow[2] = b2;
    assign borrow[3] = b3;
    assign borrow[4] = b4;
    assign borrow[5] = b5;
    assign borrow[6] = b6;
    assign borrow[7] = b7;
    
    // 将减法计算分为两部分，降低单个运算的扇出
    // 低4位的差值计算
    assign diff[0] = subtractor_a_buf1[0] ^ subtractor_b_buf1[0];
    assign diff[1] = subtractor_a_buf1[1] ^ subtractor_b_buf1[1] ^ b1;
    assign diff[2] = subtractor_a_buf1[2] ^ subtractor_b_buf1[2] ^ b2;
    assign diff[3] = subtractor_a_buf1[3] ^ subtractor_b_buf1[3] ^ b3;
    
    // 高4位的差值计算
    assign diff[4] = subtractor_a_buf2[4] ^ subtractor_b_buf2[4] ^ b4_reg;
    assign diff[5] = subtractor_a_buf2[5] ^ subtractor_b_buf2[5] ^ b5;
    assign diff[6] = subtractor_a_buf2[6] ^ subtractor_b_buf2[6] ^ b6;
    assign diff[7] = subtractor_a_buf2[7] ^ subtractor_b_buf2[7] ^ b7;
    
    // 主寄存器逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_data <= 0;
            subtractor_a <= 8'b0;
            subtractor_b <= 8'b0;
        end
        else if (!stall) begin
            if (load) begin
                current_data <= new_data;
                // 设置减法器输入值用于潜在计算
                subtractor_a <= {4'b0, new_data};
                subtractor_b <= 8'b00000001; // 常数1，用于递减
            end
            else begin
                // 使用减法结果进行条件更新
                subtractor_a <= {4'b0, current_data};
                current_data <= current_data;
            end
        end
    end
endmodule