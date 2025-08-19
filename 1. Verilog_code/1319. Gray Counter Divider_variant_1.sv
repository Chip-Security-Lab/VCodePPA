//SystemVerilog
module gray_counter_div (
    input wire clk,
    input wire rst,
    
    // Valid-Ready握手接口
    input wire ready,          // 接收方就绪信号
    output wire valid,         // 发送方数据有效信号
    output wire [3:0] data,    // 数据输出
    
    output wire divided_clk
);
    reg [3:0] gray_count;
    wire [3:0] next_gray;
    
    // 中间信号 - 移除了之前的管道寄存器
    wire and_result = gray_count[1] & gray_count[0];
    
    // 直接计算下一个格雷码
    assign next_gray[0] = ~gray_count[0];
    assign next_gray[1] = gray_count[1] ^ gray_count[0];
    assign next_gray[2] = gray_count[2] ^ and_result;
    
    // 第二级管道寄存器 - 将靠近输入的寄存器向前推移
    reg and_result_delayed;
    reg gray_count2_delayed;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            and_result_delayed <= 1'b0;
            gray_count2_delayed <= 1'b0;
        end
        else begin
            and_result_delayed <= and_result;
            gray_count2_delayed <= gray_count[2];
        end
    end
    
    // 使用前移的寄存器完成最高位计算
    assign next_gray[3] = gray_count[3] ^ (gray_count2_delayed & and_result_delayed);
    
    // 握手逻辑控制计数器更新
    reg valid_r;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_count <= 4'b0000;
            valid_r <= 1'b0;
        end
        else begin
            valid_r <= 1'b1; // 每个周期都准备提供新数据
            
            // 只有当ready信号有效时才更新计数器
            if (ready && valid_r) begin
                gray_count <= next_gray;
            end
        end
    end
    
    // 输出数据就是当前的格雷码计数值
    assign data = gray_count;
    assign valid = valid_r;
    assign divided_clk = gray_count[3];
endmodule