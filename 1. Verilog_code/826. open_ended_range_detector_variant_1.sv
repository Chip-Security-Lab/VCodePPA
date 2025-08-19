//SystemVerilog
module open_ended_range_detector(
    input wire clk,           // 时钟信号用于流水线寄存器
    input wire rst_n,         // 复位信号用于初始化
    input wire [11:0] data,
    input wire [11:0] bound_value,
    input wire direction,     // 0=lower_bound_only, 1=upper_bound_only
    output reg in_valid_zone  // 寄存器输出
);
    // 流水线阶段信号声明
    reg [11:0] data_r;
    reg [11:0] bound_value_r;
    reg direction_r;
    
    // 比较结果中间信号
    wire is_less_equal;
    wire is_greater_equal;
    
    // 第一级流水线 - 数据输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= 12'b0;
        end else begin
            data_r <= data;
        end
    end
    
    // 第一级流水线 - 边界值寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bound_value_r <= 12'b0;
        end else begin
            bound_value_r <= bound_value;
        end
    end
    
    // 第一级流水线 - 方向控制寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            direction_r <= 1'b0;
        end else begin
            direction_r <= direction;
        end
    end
    
    // 数据通路比较逻辑 - 并行计算两种比较结果
    assign is_less_equal = (data_r <= bound_value_r);
    assign is_greater_equal = (data_r >= bound_value_r);
    
    // 第二级流水线 - 结果选择和输出寄存器阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid_zone <= 1'b0;
        end else begin
            in_valid_zone <= direction_r ? is_less_equal : is_greater_equal;
        end
    end
    
endmodule