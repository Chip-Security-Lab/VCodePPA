//SystemVerilog
module configurable_range_detector(
    input wire clock, resetn,
    input wire [15:0] data,
    input wire [15:0] bound_a, bound_b,
    input wire [1:0] mode, // 00:in_range, 01:out_range, 10:above_only, 11:below_only
    output wire detect_flag
);
    // 内部连线
    wire in_range_condition;
    wire comparison_result;
    wire detect_flag_next;
    
    // 实例化纯组合逻辑模块
    range_detector_comb u_range_detector_comb (
        .data(data),
        .bound_a(bound_a),
        .bound_b(bound_b),
        .mode(mode),
        .detect_flag_next(comparison_result)
    );
    
    // 实例化纯时序逻辑模块
    range_detector_seq u_range_detector_seq (
        .clock(clock),
        .resetn(resetn),
        .detect_flag_next(comparison_result),
        .detect_flag(detect_flag)
    );
endmodule

// 纯组合逻辑模块 - 包含所有范围检测的组合逻辑
module range_detector_comb (
    input wire [15:0] data,
    input wire [15:0] bound_a, bound_b,
    input wire [1:0] mode,
    output wire detect_flag_next
);
    // 基本组合逻辑信号
    wire above_a, below_b, in_range;
    reg mode_result;
    
    // 范围比较逻辑
    assign above_a = (data >= bound_a);
    assign below_b = (data <= bound_b);
    assign in_range = above_a && below_b;
    
    // 模式选择组合逻辑
    always @(*) begin
        case(mode)
            2'b00: mode_result = in_range;      // 在范围内
            2'b01: mode_result = !in_range;     // 在范围外
            2'b10: mode_result = above_a;       // 仅高于下界
            2'b11: mode_result = below_b;       // 仅低于上界
            default: mode_result = 1'b0;        // 默认值
        endcase
    end
    
    // 组合逻辑输出
    assign detect_flag_next = mode_result;
endmodule

// 纯时序逻辑模块 - 处理所有寄存器和时钟相关逻辑
module range_detector_seq (
    input wire clock,
    input wire resetn,
    input wire detect_flag_next,
    output reg detect_flag
);
    // 时序逻辑 - 将组合逻辑结果同步到时钟域
    always @(posedge clock or negedge resetn) begin
        if (!resetn) 
            detect_flag <= 1'b0;
        else 
            detect_flag <= detect_flag_next;
    end
endmodule