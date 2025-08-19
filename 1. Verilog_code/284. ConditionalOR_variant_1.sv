//SystemVerilog
module ConditionalOR(
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire cond,       // 条件输入
    input wire [7:0] mask, // 掩码输入  
    input wire [7:0] data, // 数据输入
    output reg [7:0] result // 结果输出
);
    // 分段处理数据流
    reg cond_r1, cond_r2;
    reg [7:0] mask_r1, data_r1, data_r2;
    reg [3:0] mask_high_r1, mask_low_r1;
    reg [3:0] data_high_r1, data_low_r1;
    reg [3:0] masked_data_high, masked_data_low;
    
    // 第一级流水线 - 输入寄存并拆分高低位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cond_r1 <= 1'b0;
            mask_r1 <= 8'h00;
            data_r1 <= 8'h00;
            mask_high_r1 <= 4'h0;
            mask_low_r1 <= 4'h0;
            data_high_r1 <= 4'h0;
            data_low_r1 <= 4'h0;
        end else begin
            cond_r1 <= cond;
            mask_r1 <= mask;
            data_r1 <= data;
            // 拆分高低位以并行处理
            mask_high_r1 <= mask[7:4];
            mask_low_r1 <= mask[3:0];
            data_high_r1 <= data[7:4];
            data_low_r1 <= data[3:0];
        end
    end
    
    // 第二级流水线 - 并行掩码操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_high <= 4'h0;
            masked_data_low <= 4'h0;
            cond_r2 <= 1'b0;
            data_r2 <= 8'h00;
        end else begin
            // 高低位并行OR操作
            masked_data_high <= data_high_r1 | mask_high_r1;
            masked_data_low <= data_low_r1 | mask_low_r1;
            // 传递控制信号和原始数据到下一级
            cond_r2 <= cond_r1;
            data_r2 <= data_r1;
        end
    end
    
    // 第三级流水线 - 合并结果并进行条件选择
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'h00;
        end else begin
            // 条件选择逻辑
            if (cond_r2)
                result <= {masked_data_high, masked_data_low};
            else
                result <= data_r2;
        end
    end
    
endmodule