//SystemVerilog
module configurable_range_detector(
    input wire clock, resetn,
    input wire [15:0] data,
    input wire [15:0] bound_a, bound_b,
    input wire [1:0] mode,
    output reg detect_flag
);
    // 内部寄存器
    reg [15:0] data_reg;
    reg [15:0] bound_a_reg, bound_b_reg;
    reg [1:0] mode_reg;
    
    // 组合逻辑信号
    wire in_range, above_a, below_b;
    reg detect_result;
    
    // 输入寄存器
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            data_reg <= 16'b0;
            bound_a_reg <= 16'b0;
            bound_b_reg <= 16'b0;
            mode_reg <= 2'b0;
        end else begin
            data_reg <= data;
            bound_a_reg <= bound_a;
            bound_b_reg <= bound_b;
            mode_reg <= mode;
        end
    end
    
    // 范围检测组合逻辑
    assign above_a = (data_reg >= bound_a_reg);
    assign below_b = (data_reg <= bound_b_reg);
    assign in_range = above_a && below_b;
    
    // 模式选择组合逻辑
    always @(*) begin
        case(mode_reg)
            2'b00: detect_result = in_range;
            2'b01: detect_result = !in_range;
            2'b10: detect_result = above_a;
            2'b11: detect_result = below_b;
            default: detect_result = 1'b0;
        endcase
    end
    
    // 输出寄存器
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            detect_flag <= 1'b0;
        else
            detect_flag <= detect_result;
    end
endmodule