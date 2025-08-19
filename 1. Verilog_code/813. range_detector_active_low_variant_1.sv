//SystemVerilog
module range_detector_active_low(
    input wire clock, reset,
    input wire [7:0] value,
    input wire [7:0] range_low, range_high,
    output reg range_valid_n
);
    reg [7:0] value_reg, range_low_reg, range_high_reg;
    reg reset_reg;
    
    // 寄存器向后移动，在组合逻辑前注册输入信号
    always @(posedge clock) begin
        value_reg <= value;
        range_low_reg <= range_low;
        range_high_reg <= range_high;
        reset_reg <= reset;
    end
    
    wire comp_result_n;
    
    comparator_low comp1 (
        .in_value(value_reg),
        .lower_lim(range_low_reg),
        .upper_lim(range_high_reg),
        .out_of_range(comp_result_n)
    );
    
    // 寄存器逻辑保持不变
    always @(posedge clock) begin
        range_valid_n <= reset_reg ? 1'b1 : comp_result_n;
    end
endmodule

module comparator_low(
    input wire [7:0] in_value,
    input wire [7:0] lower_lim,
    input wire [7:0] upper_lim,
    output wire out_of_range
);
    assign out_of_range = (in_value < lower_lim) || (in_value > upper_lim);
endmodule