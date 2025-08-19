//SystemVerilog
module barrel_rot_bi_dir (
    input wire clk,               // 时钟信号
    input wire rst_n,             // 复位信号
    input wire [31:0] data_in,    // 输入数据
    input wire [4:0] shift_val,   // 移位值
    input wire direction,         // 移位方向: 0-左移, 1-右移
    output reg [31:0] data_out    // 寄存器化输出
);
    // 第一级流水线寄存器 - 捕获输入
    reg [31:0] data_reg;
    reg [4:0] shift_val_reg;
    reg direction_reg;
    
    // 第二级流水线的中间计算值
    reg [31:0] shift_partial_left1, shift_partial_left2;
    reg [31:0] shift_partial_right1, shift_partial_right2;
    reg [4:0] shift_val_stage2;
    reg direction_stage2;
    
    // 第三级流水线变量
    reg [31:0] left_result_reg, right_result_reg;
    reg direction_stage3;
    
    // 第一级流水线 - 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'b0;
            shift_val_reg <= 5'b0;
            direction_reg <= 1'b0;
        end else begin
            data_reg <= data_in;
            shift_val_reg <= shift_val;
            direction_reg <= direction;
        end
    end
    
    // 第二级流水线 - 分解移位操作为两步，减少关键路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_partial_left1 <= 32'b0;
            shift_partial_left2 <= 32'b0;
            shift_partial_right1 <= 32'b0;
            shift_partial_right2 <= 32'b0;
            shift_val_stage2 <= 5'b0;
            direction_stage2 <= 1'b0;
        end else begin
            // 左移计算的拆分 - 先处理低位移位，减少逻辑关键路径
            shift_partial_left1 <= (shift_val_reg[2:0] > 0) ? (data_reg << shift_val_reg[2:0]) : data_reg;
            shift_partial_left2 <= (32 - {2'b0, shift_val_reg[2:0]}) < 32 ? 
                                  (data_reg >> (32 - {2'b0, shift_val_reg[2:0]})) : 32'b0;
            
            // 右移计算的拆分 - 先处理低位移位，减少逻辑关键路径
            shift_partial_right1 <= (shift_val_reg[2:0] > 0) ? (data_reg >> shift_val_reg[2:0]) : data_reg;
            shift_partial_right2 <= (32 - {2'b0, shift_val_reg[2:0]}) < 32 ? 
                                   (data_reg << (32 - {2'b0, shift_val_reg[2:0]})) : 32'b0;
            
            // 传递高位移位值到下一阶段
            shift_val_stage2 <= shift_val_reg;
            direction_stage2 <= direction_reg;
        end
    end
    
    // 第三级流水线 - 完成移位操作并合并结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_result_reg <= 32'b0;
            right_result_reg <= 32'b0;
            direction_stage3 <= 1'b0;
        end else begin
            // 完成左移操作 - 处理高位移位并合并结果
            left_result_reg <= (shift_val_stage2[4:3] > 0) ? 
                              ((shift_partial_left1 << (shift_val_stage2[4:3] << 3)) | 
                               (shift_partial_left2 << (shift_val_stage2[4:3] << 3)) | 
                               (shift_partial_left1 >> (32 - (shift_val_stage2[4:3] << 3)))) : 
                              (shift_partial_left1 | shift_partial_left2);
            
            // 完成右移操作 - 处理高位移位并合并结果
            right_result_reg <= (shift_val_stage2[4:3] > 0) ? 
                               ((shift_partial_right1 >> (shift_val_stage2[4:3] << 3)) | 
                                (shift_partial_right2 >> (shift_val_stage2[4:3] << 3)) | 
                                (shift_partial_right1 << (32 - (shift_val_stage2[4:3] << 3)))) : 
                               (shift_partial_right1 | shift_partial_right2);
            
            direction_stage3 <= direction_stage2;
        end
    end
    
    // 第四级流水线 - 根据方向选择输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
        end else begin
            data_out <= direction_stage3 ? right_result_reg : left_result_reg;
        end
    end
    
endmodule