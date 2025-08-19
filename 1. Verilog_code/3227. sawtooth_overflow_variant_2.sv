//SystemVerilog
// 顶层模块
module sawtooth_overflow(
    input clk,
    input rst,
    input [7:0] increment,
    output [7:0] sawtooth,
    output overflow
);
    // 内部连线
    wire [8:0] sum_result;
    
    // 计算模块实例化
    sawtooth_calculator calculator_inst (
        .clk(clk),
        .rst(rst),
        .increment(increment),
        .sum_result(sum_result)
    );
    
    // 输出寄存器模块实例化
    sawtooth_output_register output_reg_inst (
        .clk(clk),
        .rst(rst),
        .sum_result(sum_result),
        .sawtooth(sawtooth),
        .overflow(overflow)
    );
endmodule

// 计算模块 - 负责计算锯齿波的下一个值
module sawtooth_calculator(
    input clk,
    input rst,
    input [7:0] increment,
    output reg [8:0] sum_result
);
    reg [7:0] current_value;
    
    always @(posedge clk) begin
        if (rst) begin
            current_value <= 8'd0;
            sum_result <= 9'd0;
        end else begin
            sum_result <= current_value + increment;
            current_value <= current_value + increment;
        end
    end
endmodule

// 输出寄存器模块 - 负责提取和注册输出
module sawtooth_output_register(
    input clk,
    input rst,
    input [8:0] sum_result,
    output reg [7:0] sawtooth,
    output reg overflow
);
    always @(posedge clk) begin
        if (rst) begin
            sawtooth <= 8'd0;
            overflow <= 1'b0;
        end else begin
            sawtooth <= sum_result[7:0];
            overflow <= sum_result[8];
        end
    end
endmodule