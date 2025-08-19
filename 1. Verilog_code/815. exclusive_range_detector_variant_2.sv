//SystemVerilog
module exclusive_range_detector(
    input wire clk,
    input wire rst_n,  // 添加复位信号
    input wire valid_in,  // 输入有效信号
    input wire [9:0] data_val,
    input wire [9:0] lower_val, upper_val,
    input wire inclusive, // 0=exclusive, 1=inclusive
    output wire range_match,
    output wire valid_out  // 输出有效信号
);
    // 第一级流水线寄存器及组合逻辑
    reg [9:0] data_val_stage1, lower_val_stage1, upper_val_stage1;
    reg inclusive_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器及组合逻辑
    reg low_check_stage2, high_check_stage2;
    reg valid_stage2;
    
    // 第三级流水线寄存器
    reg result_stage3;
    reg valid_stage3;
    
    // 第一级流水线 - 输入寄存和比较准备
    always @(posedge clk) begin
        if (!rst_n) begin
            data_val_stage1 <= 10'b0;
            lower_val_stage1 <= 10'b0;
            upper_val_stage1 <= 10'b0;
            inclusive_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_val_stage1 <= data_val;
            lower_val_stage1 <= lower_val;
            upper_val_stage1 <= upper_val;
            inclusive_stage1 <= inclusive;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 执行比较操作
    always @(posedge clk) begin
        if (!rst_n) begin
            low_check_stage2 <= 1'b0;
            high_check_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 执行范围检查
            low_check_stage2 <= inclusive_stage1 ? 
                               (data_val_stage1 >= lower_val_stage1) : 
                               (data_val_stage1 > lower_val_stage1);
            high_check_stage2 <= inclusive_stage1 ? 
                                (data_val_stage1 <= upper_val_stage1) : 
                                (data_val_stage1 < upper_val_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 合并结果
    always @(posedge clk) begin
        if (!rst_n) begin
            result_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            result_stage3 <= low_check_stage2 && high_check_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign range_match = result_stage3;
    assign valid_out = valid_stage3;
    
endmodule