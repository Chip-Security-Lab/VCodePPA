//SystemVerilog
// 顶层模块
module RepeatDetector #(
    parameter WIN = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    output wire [15:0] code
);

    // 内部连线
    wire [7:0] current_data;
    wire [7:0] previous_data;
    wire is_repeat;
    wire [3:0] current_ptr;

    // 历史数据存储模块实例
    HistoryBuffer #(
        .WIN(WIN)
    ) history_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data),
        .current_data(current_data),
        .previous_data(previous_data),
        .ptr(current_ptr)
    );

    // 重复检测模块实例
    RepeatAnalyzer repeat_analyzer_inst (
        .current_data(current_data),
        .previous_data(previous_data),
        .ptr(current_ptr),
        .win_size(WIN),
        .is_repeat(is_repeat)
    );

    // 编码生成模块实例
    CodeGenerator code_generator_inst (
        .data(current_data),
        .is_repeat(is_repeat),
        .code(code)
    );

endmodule

// 历史数据缓冲模块
module HistoryBuffer #(
    parameter WIN = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output wire [7:0] current_data,
    output wire [7:0] previous_data,
    output reg [3:0] ptr
);

    reg [7:0] history [0:WIN-1];
    integer i;

    // 初始化
    initial begin
        ptr = 0;
        for(i=0; i<WIN; i=i+1)
            history[i] = 0;
    end

    // 数据存储及指针更新
    always @(posedge clk) begin
        if(!rst_n) begin
            for(i=0; i<WIN; i=i+1)
                history[i] <= 0;
            ptr <= 0;
        end
        else begin
            history[ptr] <= data_in;
            ptr <= (ptr == WIN-1) ? 0 : ptr + 1;
        end
    end

    // 输出当前数据
    assign current_data = data_in;
    
    // 输出前一个数据
    assign previous_data = (ptr > 0) ? history[ptr-1] : history[WIN-1];

endmodule

// 重复检测分析模块
module RepeatAnalyzer (
    input wire [7:0] current_data,
    input wire [7:0] previous_data,
    input wire [3:0] ptr,
    input wire [3:0] win_size,
    output wire is_repeat
);

    // 检测当前数据是否与前一个数据相同
    assign is_repeat = (current_data == previous_data);

endmodule

// 编码生成模块
module CodeGenerator (
    input wire [7:0] data,
    input wire is_repeat,
    output reg [15:0] code
);

    // 基于重复状态生成输出编码
    always @(*) begin
        if(is_repeat)
            code = {8'hFF, data};
        else
            code = {8'h00, data};
    end

endmodule