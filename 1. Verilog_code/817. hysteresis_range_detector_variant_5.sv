//SystemVerilog
module hysteresis_range_detector(
    input wire clock, reset_n,
    input wire [7:0] input_data,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output reg in_valid_range
);
    // 注册滞回状态信号以减少扇出负载
    reg in_valid_range_buffered;
    
    // 将高扇出信号in_valid_range缓冲到寄存器中
    always @(posedge clock or negedge reset_n)
        if (!reset_n) in_valid_range_buffered <= 1'b0;
        else in_valid_range_buffered <= in_valid_range;
    
    // 分割计算逻辑，减少关键路径延迟
    reg [7:0] effective_low_reg, effective_high_reg;
    wire [7:0] low_with_hysteresis = low_bound - hysteresis;
    wire [7:0] high_with_hysteresis = high_bound + hysteresis;
    
    // 注册计算的边界值，减少组合逻辑延迟
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            effective_low_reg <= 8'b0;
            effective_high_reg <= 8'b0;
        end
        else begin
            effective_low_reg <= in_valid_range_buffered ? low_with_hysteresis : low_bound;
            effective_high_reg <= in_valid_range_buffered ? high_with_hysteresis : high_bound;
        end
    
    // 使用注册后的边界值进行范围检测
    wire in_range_now;
    assign in_range_now = (input_data >= effective_low_reg) && (input_data <= effective_high_reg);
    
    // 更新输出寄存器
    always @(posedge clock or negedge reset_n)
        if (!reset_n) in_valid_range <= 1'b0;
        else in_valid_range <= in_range_now;
endmodule