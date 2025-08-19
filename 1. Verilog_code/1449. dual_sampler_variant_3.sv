//SystemVerilog
//IEEE 1364-2005 Verilog
module dual_sampler (
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire din,
    input wire valid_in,  // 输入有效信号
    output wire rise_data,
    output wire fall_data,
    output wire valid_out  // 输出有效信号
);
    // 流水线寄存器 - 第一级
    reg din_stage1;
    reg valid_stage1;
    
    // 流水线寄存器 - 第二级
    reg din_stage2;
    reg valid_stage2;
    
    // 流水线寄存器 - 输出级
    reg rise_data_reg;
    reg fall_data_reg;
    reg valid_out_reg;
    
    // 采样边沿检测寄存器
    reg din_prev;
    
    // 第一级流水线 - 缓存输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            din_prev <= 1'b0;
        end else begin
            din_stage1 <= din;
            valid_stage1 <= valid_in;
            din_prev <= din_stage1;
        end
    end
    
    // 第二级流水线 - 处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 上升沿采样逻辑 - 在主时钟的正边沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rise_data_reg <= 1'b0;
        end else if (valid_stage2) begin
            rise_data_reg <= din_stage2;
        end
    end
    
    // 下降沿采样逻辑 - 使用捕获的前一个值进行边缘检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fall_data_reg <= 1'b0;
        end else if (valid_stage2) begin
            // 检测下降沿
            if (din_prev && !din_stage2) begin
                fall_data_reg <= din_stage2;
            end
        end
    end
    
    // 输出有效信号逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out_reg <= 1'b0;
        end else begin
            valid_out_reg <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign rise_data = rise_data_reg;
    assign fall_data = fall_data_reg;
    assign valid_out = valid_out_reg;
    
endmodule