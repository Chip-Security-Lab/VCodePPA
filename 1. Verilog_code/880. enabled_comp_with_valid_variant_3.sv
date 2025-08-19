//SystemVerilog
//-----------------------------------------------------------------------------
// Top Module: 启用比较器顶层模块
//-----------------------------------------------------------------------------
module enabled_comp_with_valid #(
    parameter WIDTH = 4
)(
    input                           clock,
    input                           reset,
    input                           enable,
    input      [WIDTH-1:0]          in_values [0:WIDTH-1],
    output     [$clog2(WIDTH)-1:0]  highest_idx,
    output                          valid_result
);
    // 内部连接信号
    wire [WIDTH-1:0]          max_value_wire;
    wire [$clog2(WIDTH)-1:0]  highest_idx_wire;
    wire                      valid_result_wire;
    
    // 比较器子模块
    value_comparator #(
        .WIDTH(WIDTH)
    ) u_value_comparator (
        .clock        (clock),
        .reset        (reset),
        .enable       (enable),
        .in_values    (in_values),
        .max_value    (max_value_wire),
        .highest_idx  (highest_idx_wire)
    );
    
    // 输出控制子模块
    output_controller u_output_controller (
        .clock        (clock),
        .reset        (reset),
        .enable       (enable),
        .highest_idx_in (highest_idx_wire),
        .highest_idx  (highest_idx),
        .valid_result (valid_result)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 比较器子模块：负责找出最大值及其索引
//-----------------------------------------------------------------------------
module value_comparator #(
    parameter WIDTH = 4
)(
    input                           clock,
    input                           reset,
    input                           enable,
    input      [WIDTH-1:0]          in_values [0:WIDTH-1],
    output reg [WIDTH-1:0]          max_value,
    output reg [$clog2(WIDTH)-1:0]  highest_idx
);
    // 本地变量
    integer j;
    
    always @(posedge clock) begin
        if (reset) begin
            max_value <= 0;
            highest_idx <= 0;
        end else if (enable) begin
            // 初始化为第一个值
            max_value <= in_values[0];
            highest_idx <= 0;
            
            // 查找最大值
            for (j = 1; j < WIDTH; j = j + 1) begin
                if (in_values[j] > max_value) begin
                    max_value <= in_values[j];
                    highest_idx <= j[$clog2(WIDTH)-1:0];
                end
            end
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 输出控制子模块：处理输出和有效信号
//-----------------------------------------------------------------------------
module output_controller (
    input                          clock,
    input                          reset,
    input                          enable,
    input      [$clog2(WIDTH)-1:0] highest_idx_in,
    output reg [$clog2(WIDTH)-1:0] highest_idx,
    output reg                     valid_result
);
    parameter WIDTH = 4; // 保持与顶层模块一致
    
    always @(posedge clock) begin
        if (reset) begin
            highest_idx <= 0;
            valid_result <= 0;
        end else if (enable) begin
            highest_idx <= highest_idx_in;
            valid_result <= 1;
        end else begin
            valid_result <= 0;
        end
    end
endmodule