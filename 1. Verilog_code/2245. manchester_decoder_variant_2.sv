//SystemVerilog
module manchester_decoder (
    input  wire clk,           // 时钟输入
    input  wire rst_n,         // 复位信号
    input  wire encoded,       // 编码输入
    output reg  decoded,       // 解码输出
    output reg  clk_recovered  // 恢复的时钟
);
    // 第一级流水线寄存器
    reg encoded_stage1;
    reg prev_bit_stage1;
    
    // 第二级流水线寄存器
    reg encoded_stage2;
    reg prev_bit_stage2;
    reg edge_detected_stage2;
    
    // 第三级流水线寄存器
    reg decoded_stage3;
    reg clk_recovered_stage3;
    
    // 第一级流水线 - 数据采样
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage1 <= 1'b0;
            prev_bit_stage1 <= 1'b0;
        end else begin
            encoded_stage1 <= encoded;
            prev_bit_stage1 <= encoded_stage1;
        end
    end
    
    // 第二级流水线 - 边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage2 <= 1'b0;
            prev_bit_stage2 <= 1'b0;
            edge_detected_stage2 <= 1'b0;
        end else begin
            encoded_stage2 <= encoded_stage1;
            prev_bit_stage2 <= prev_bit_stage1;
            edge_detected_stage2 <= (encoded_stage1 != prev_bit_stage1);
        end
    end
    
    // 第三级流水线 - 解码逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_stage3 <= 1'b0;
            clk_recovered_stage3 <= 1'b0;
        end else begin
            if (edge_detected_stage2) begin
                decoded_stage3 <= encoded_stage2;
                clk_recovered_stage3 <= 1'b1;
            end else begin
                // 保持上一个值
                decoded_stage3 <= decoded_stage3;
                clk_recovered_stage3 <= 1'b0;
            end
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 1'b0;
            clk_recovered <= 1'b0;
        end else begin
            decoded <= decoded_stage3;
            clk_recovered <= clk_recovered_stage3;
        end
    end
endmodule