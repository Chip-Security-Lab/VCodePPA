//SystemVerilog - IEEE 1364-2005
//顶层模块
module async_rst_latch #(parameter WIDTH=8)(
    input wire rst,
    input wire en,
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] latch_out
);
    // 内部信号
    wire [1:0] ctrl_signals;
    wire [WIDTH-1:0] latch_data;
    
    // 控制信号生成子模块
    ctrl_signal_generator ctrl_gen (
        .rst(rst),
        .en(en),
        .ctrl_out(ctrl_signals)
    );
    
    // 数据处理子模块
    data_processor #(
        .WIDTH(WIDTH)
    ) data_proc (
        .ctrl(ctrl_signals),
        .din(din),
        .current_value(latch_out),
        .latch_data(latch_data)
    );
    
    // 输出锁存子模块
    output_latch #(
        .WIDTH(WIDTH)
    ) out_latch (
        .data_in(latch_data),
        .data_out(latch_out)
    );
    
endmodule

//控制信号生成子模块
module ctrl_signal_generator (
    input wire rst,
    input wire en,
    output reg [1:0] ctrl_out
);
    // 生成优先级编码的控制信号
    always @(*) begin
        ctrl_out = {rst, en};
    end
endmodule

//数据处理子模块
module data_processor #(parameter WIDTH=8)(
    input wire [1:0] ctrl,
    input wire [WIDTH-1:0] din,
    input wire [WIDTH-1:0] current_value,
    output reg [WIDTH-1:0] latch_data
);
    // 根据控制信号处理数据
    always @(*) begin
        case(ctrl)
            2'b10,  // rst=1, en=0
            2'b11:  // rst=1, en=1 (rst优先)
                latch_data = {WIDTH{1'b0}};
                
            2'b01:  // rst=0, en=1
                latch_data = din;
                
            2'b00:  // rst=0, en=0
                latch_data = current_value; // 保持当前值
                
            default: // 为了完整性
                latch_data = {WIDTH{1'b0}};
        endcase
    end
endmodule

//输出锁存子模块
module output_latch #(parameter WIDTH=8)(
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 锁存输出数据
    always @(*) begin
        data_out = data_in;
    end
endmodule