//SystemVerilog
module error_flagging_range_detector(
    input wire clk, rst,
    input wire [31:0] data_in,
    input wire [31:0] lower_lim, upper_lim,
    output reg in_range,
    output reg error_flag
);
    // 预计算比较结果
    wire valid_range;
    wire in_bounds;
    
    // 使用减法比较器代替直接比较以优化面积
    assign valid_range = ~(upper_lim[31] & ~lower_lim[31]) &  // 处理符号位
                        ((upper_lim[31] == lower_lim[31]) ? 
                         (upper_lim[30:0] >= lower_lim[30:0]) : 
                         upper_lim[31]);
    
    // 使用三元运算符优化比较链逻辑
    assign in_bounds = valid_range ? 
                     (~(data_in[31] & ~lower_lim[31]) &  // 处理data_in与lower_lim符号位
                     ((data_in[31] == lower_lim[31]) ? 
                      (data_in[30:0] >= lower_lim[30:0]) : 
                      lower_lim[31]) &
                     (~(upper_lim[31] & ~data_in[31]) &  // 处理upper_lim与data_in符号位
                     ((upper_lim[31] == data_in[31]) ? 
                      (upper_lim[30:0] >= data_in[30:0]) : 
                      data_in[31]))) : 
                     1'b0;  // 如果范围无效，则一定不在范围内
    
    // 时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin 
            in_range <= 1'b0; 
            error_flag <= 1'b0; 
        end
        else begin
            error_flag <= ~valid_range;  // 使用非运算来提高清晰度
            in_range <= in_bounds;       // 已经包含valid_range检查
        end
    end
endmodule