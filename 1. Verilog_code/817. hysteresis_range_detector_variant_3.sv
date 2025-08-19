//SystemVerilog
//----------------------------------------
// 顶层模块：滞环范围检测器
//----------------------------------------
module hysteresis_range_detector(
    input wire clock, reset_n,
    input wire [7:0] input_data,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output wire in_valid_range
);
    // 内部信号
    wire in_range_now;
    wire [7:0] effective_low, effective_high;
    
    // 计算有效边界子模块
    boundary_calculator u_boundary_calc (
        .in_valid_range(in_valid_range),
        .low_bound(low_bound),
        .high_bound(high_bound),
        .hysteresis(hysteresis),
        .effective_low(effective_low),
        .effective_high(effective_high)
    );
    
    // 范围比较器子模块
    range_comparator u_range_comp (
        .input_data(input_data),
        .effective_low(effective_low),
        .effective_high(effective_high),
        .in_range_now(in_range_now)
    );
    
    // 状态寄存器子模块
    state_register u_state_reg (
        .clock(clock),
        .reset_n(reset_n),
        .in_range_now(in_range_now),
        .in_valid_range(in_valid_range)
    );
    
endmodule

//----------------------------------------
// 子模块：边界计算器
//----------------------------------------
module boundary_calculator(
    input wire in_valid_range,
    input wire [7:0] low_bound, high_bound,
    input wire [3:0] hysteresis,
    output wire [7:0] effective_low, effective_high
);
    // 参数化设计，使用函数替代直接运算
    function [7:0] calc_low_threshold;
        input [7:0] base_low;
        input [3:0] hyst;
        input in_range;
        begin
            if (in_range) begin
                calc_low_threshold = base_low - hyst;
            end else begin
                calc_low_threshold = base_low;
            end
        end
    endfunction
    
    function [7:0] calc_high_threshold;
        input [7:0] base_high;
        input [3:0] hyst;
        input in_range;
        begin
            if (in_range) begin
                calc_high_threshold = base_high + hyst;
            end else begin
                calc_high_threshold = base_high;
            end
        end
    endfunction
    
    // 并行计算有效边界，提高性能
    assign effective_low = calc_low_threshold(low_bound, hysteresis, in_valid_range);
    assign effective_high = calc_high_threshold(high_bound, hysteresis, in_valid_range);
    
endmodule

//----------------------------------------
// 子模块：范围比较器
//----------------------------------------
module range_comparator(
    input wire [7:0] input_data,
    input wire [7:0] effective_low, effective_high,
    output wire in_range_now
);
    // 使用独立的比较信号，增强可读性和时序优化
    wire above_low_bound, below_high_bound;
    
    assign above_low_bound = (input_data >= effective_low);
    assign below_high_bound = (input_data <= effective_high);
    assign in_range_now = above_low_bound && below_high_bound;
    
endmodule

//----------------------------------------
// 子模块：状态寄存器
//----------------------------------------
module state_register(
    input wire clock, reset_n,
    input wire in_range_now,
    output reg in_valid_range
);
    // 同步复位逻辑优化
    always @(posedge clock) begin
        if (!reset_n)
            in_valid_range <= 1'b0;
        else
            in_valid_range <= in_range_now;
    end
    
endmodule