//SystemVerilog
//IEEE 1364-2005
// 顶层模块 - 调度并连接各个功能子模块
module tdm_crossbar (
    input wire clock, reset,
    input wire [7:0] in0, in1, in2, in3,
    output wire [7:0] out0, out1, out2, out3
);
    // 时间槽计数器信号
    wire [1:0] time_slot;
    
    // 从输入源到交叉矩阵的内部连线
    wire [31:0] input_bus;
    
    // 从交叉矩阵到输出的内部连线
    wire [31:0] output_bus;
    
    // 实例化时间槽控制器
    time_slot_controller time_controller (
        .clock(clock),
        .reset(reset),
        .time_slot(time_slot)
    );
    
    // 实例化输入处理器
    input_processor input_proc (
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .input_bus(input_bus)
    );
    
    // 实例化交叉连接矩阵
    crossbar_matrix matrix (
        .input_bus(input_bus),
        .time_slot(time_slot),
        .output_bus(output_bus)
    );
    
    // 实例化输出处理器
    output_processor output_proc (
        .output_bus(output_bus),
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3)
    );
    
endmodule

// 时间槽控制器模块 - 负责生成调度时间槽
module time_slot_controller (
    input wire clock, reset,
    output reg [1:0] time_slot
);
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            time_slot <= 2'b00;
        end else begin
            // 循环时间槽
            time_slot <= time_slot + 1'b1;
        end
    end
    
endmodule

// 输入处理器模块 - 将各个输入端口的数据合并成一个总线
module input_processor (
    input wire [7:0] in0, in1, in2, in3,
    output wire [31:0] input_bus
);
    
    // 将各个8位输入合并为32位总线
    assign input_bus = {in3, in2, in1, in0};
    
endmodule

// 交叉连接矩阵模块 - 实现时分复用交叉连接
module crossbar_matrix (
    input wire [31:0] input_bus,
    input wire [1:0] time_slot,
    output reg [31:0] output_bus
);
    // 从输入总线提取各个输入信号
    wire [7:0] in0 = input_bus[7:0];
    wire [7:0] in1 = input_bus[15:8];
    wire [7:0] in2 = input_bus[23:16];
    wire [7:0] in3 = input_bus[31:24];
    
    // 根据时间槽安排输出连接 - 使用if-else级联结构替代case
    always @(*) begin
        if (time_slot == 2'b00) begin
            // 正常连接
            output_bus = {in3, in2, in1, in0};
        end else if (time_slot == 2'b01) begin
            // 右移1个位置
            output_bus = {in2, in1, in0, in3};
        end else if (time_slot == 2'b10) begin
            // 右移2个位置
            output_bus = {in1, in0, in3, in2};
        end else begin
            // time_slot == 2'b11, 右移3个位置
            output_bus = {in0, in3, in2, in1};
        end
    end
    
endmodule

// 输出处理器模块 - 将总线拆分成各个输出端口
module output_processor (
    input wire [31:0] output_bus,
    output wire [7:0] out0, out1, out2, out3
);
    
    // 将32位总线拆分为各个8位输出
    assign out0 = output_bus[7:0];
    assign out1 = output_bus[15:8];
    assign out2 = output_bus[23:16];
    assign out3 = output_bus[31:24];
    
endmodule