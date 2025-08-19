//SystemVerilog
module range_detector_with_enable(
    input wire clk, rst, enable,
    input wire [15:0] data_input,
    input wire [15:0] range_min, range_max,
    output wire range_detect_flag
);
    wire comp_out;
    wire next_flag;
    
    // 组合逻辑部分
    comparator_module comp1(
        .data(data_input),
        .lower(range_min),
        .upper(range_max),
        .in_range(comp_out)
    );
    
    // 组合逻辑 - 计算下一个状态
    assign next_flag = enable ? comp_out : range_detect_flag;
    
    // 时序逻辑部分
    flag_register flag_reg(
        .clk(clk),
        .rst(rst),
        .next_flag(next_flag),
        .flag(range_detect_flag)
    );
endmodule

// 纯组合逻辑模块
module comparator_module(
    input wire [15:0] data,
    input wire [15:0] lower,
    input wire [15:0] upper,
    output wire in_range
);
    assign in_range = (data >= lower) && (data <= upper);
endmodule

// 纯时序逻辑模块
module flag_register(
    input wire clk, rst,
    input wire next_flag,
    output reg flag
);
    always @(posedge clk) begin
        if (rst)
            flag <= 1'b0;
        else
            flag <= next_flag;
    end
endmodule