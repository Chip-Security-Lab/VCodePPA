//SystemVerilog
module range_detector_active_low(
    input wire clock, reset,
    input wire [7:0] value,
    input wire [7:0] range_low, range_high,
    output reg range_valid_n,
    // 流水线控制信号
    input wire data_valid_in,
    output wire data_valid_out,
    output wire ready_for_input
);
    // 流水线阶段1寄存器
    reg [7:0] value_stage1, range_low_stage1, range_high_stage1;
    reg data_valid_stage1;
    
    // 流水线阶段2寄存器
    reg comp_result_n_stage2;
    reg data_valid_stage2;
    
    // 流水线控制逻辑
    assign ready_for_input = 1'b1; // 本设计始终可以接收新输入
    assign data_valid_out = data_valid_stage2;
    
    // 流水线阶段1到阶段2的组合逻辑
    wire comp_result_n_wire;
    
    comparator_low comp1 (
        .in_value(value_stage1),
        .lower_lim(range_low_stage1),
        .upper_lim(range_high_stage1),
        .out_of_range(comp_result_n_wire)
    );
    
    // 合并所有时序逻辑到单一always块
    always @(posedge clock) begin
        if (reset) begin
            // 流水线阶段1复位
            value_stage1 <= 8'h00;
            range_low_stage1 <= 8'h00;
            range_high_stage1 <= 8'h00;
            data_valid_stage1 <= 1'b0;
            
            // 流水线阶段2复位
            comp_result_n_stage2 <= 1'b1;
            data_valid_stage2 <= 1'b0;
            
            // 输出复位
            range_valid_n <= 1'b1;
        end
        else begin
            // 流水线阶段1逻辑
            if (ready_for_input) begin
                value_stage1 <= value;
                range_low_stage1 <= range_low;
                range_high_stage1 <= range_high;
                data_valid_stage1 <= data_valid_in;
            end
            
            // 流水线阶段2逻辑
            comp_result_n_stage2 <= comp_result_n_wire;
            data_valid_stage2 <= data_valid_stage1;
            
            // 输出逻辑
            range_valid_n <= comp_result_n_stage2;
        end
    end
endmodule

// 优化后的comparator_low模块
module comparator_low(
    input wire [7:0] in_value,
    input wire [7:0] lower_lim,
    input wire [7:0] upper_lim,
    output wire out_of_range
);
    // 并行计算下界和上界比较，提高性能
    wire below_lower = in_value < lower_lim;
    wire above_upper = in_value > upper_lim;
    
    assign out_of_range = below_lower || above_upper;
endmodule