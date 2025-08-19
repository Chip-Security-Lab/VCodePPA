//SystemVerilog
module exclusive_range_detector(
    input wire clk,
    input wire [9:0] data_val,
    input wire [9:0] lower_val, upper_val,
    input wire inclusive, // 0=exclusive, 1=inclusive
    output reg range_match
);
    // 寄存器化输入信号
    reg [9:0] data_val_reg, lower_val_reg, upper_val_reg;
    reg inclusive_reg;
    
    // 寄存器化中间结果
    reg [9:0] adjusted_lower, adjusted_upper;
    reg lower_check, upper_check;
    
    // 第一级流水线：寄存器化输入
    always @(posedge clk) begin
        data_val_reg <= data_val;
        lower_val_reg <= lower_val;
        upper_val_reg <= upper_val;
        inclusive_reg <= inclusive;
    end
    
    // 第二级流水线：计算调整后的边界值
    always @(posedge clk) begin
        adjusted_lower <= inclusive_reg ? lower_val_reg : lower_val_reg + 1'b1;
        adjusted_upper <= inclusive_reg ? upper_val_reg : upper_val_reg - 1'b1;
    end
    
    // 第三级流水线：分离比较操作
    always @(posedge clk) begin
        lower_check <= (data_val_reg >= adjusted_lower);
        upper_check <= (data_val_reg <= adjusted_upper);
    end
    
    // 第四级流水线：最终范围匹配结果
    always @(posedge clk) begin
        range_match <= lower_check && upper_check;
    end
endmodule