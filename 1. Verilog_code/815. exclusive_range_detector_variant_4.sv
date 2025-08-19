//SystemVerilog
module exclusive_range_detector(
    input wire clk,
    input wire rst,    // 添加复位信号
    input wire valid_in,  // 输入有效信号
    input wire [9:0] data_val,
    input wire [9:0] lower_val, upper_val,
    input wire inclusive, // 0=exclusive, 1=inclusive
    output reg valid_out, // 输出有效信号
    output reg range_match
);
    // 第一级流水线寄存器和信号
    reg [9:0] data_val_stage1, lower_val_stage1, upper_val_stage1;
    reg inclusive_stage1;
    reg valid_stage1;
    
    // 第二级流水线中间结果
    reg low_check_stage2, high_check_stage2;
    reg valid_stage2;
    
    // 第一级流水线: 寄存输入数据
    always @(posedge clk) begin
        if (rst) begin
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
    
    // 第二级流水线: 计算比较结果
    always @(posedge clk) begin
        if (rst) begin
            low_check_stage2 <= 1'b0;
            high_check_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            low_check_stage2 <= inclusive_stage1 ? (data_val_stage1 >= lower_val_stage1) : (data_val_stage1 > lower_val_stage1);
            high_check_stage2 <= inclusive_stage1 ? (data_val_stage1 <= upper_val_stage1) : (data_val_stage1 < upper_val_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线: 计算最终结果
    always @(posedge clk) begin
        if (rst) begin
            range_match <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            range_match <= low_check_stage2 && high_check_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule