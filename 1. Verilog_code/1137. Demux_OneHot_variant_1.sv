//SystemVerilog
// Top-level module
module Demux_OneHot #(parameter DW=16, N=4) (
    input [DW-1:0] din,
    input [N-1:0] sel,
    output [N-1:0][DW-1:0] dout
);

    // 连接子模块的信号
    wire [N-1:0][DW-1:0] output_data;
    
    // 实例化初始化模块
    Demux_Initializer #(
        .DW(DW),
        .N(N)
    ) initializer (
        .out_data(output_data)
    );
    
    // 实例化选择器模块
    Demux_Selector #(
        .DW(DW),
        .N(N)
    ) selector (
        .din(din),
        .sel(sel),
        .out_data(output_data),
        .dout(dout)
    );

endmodule

// 初始化模块 - 负责将输出初始化为0
module Demux_Initializer #(parameter DW=16, N=4) (
    output reg [N-1:0][DW-1:0] out_data
);

    integer i;
    
    always @(*) begin
        for (i = 0; i < N; i = i + 1) begin
            out_data[i] = {DW{1'b0}};
        end
    end

endmodule

// 选择器模块 - 根据选择信号选择输出
module Demux_Selector #(parameter DW=16, N=4) (
    input [DW-1:0] din,
    input [N-1:0] sel,
    input [N-1:0][DW-1:0] out_data,
    output reg [N-1:0][DW-1:0] dout
);

    integer i;
    
    always @(*) begin
        // 先复制初始化的值
        dout = out_data;
        
        // 根据选择信号设置输出
        for (i = 0; i < N; i = i + 1) begin
            if (sel[i]) begin
                dout[i] = din;
            end
        end
    end

endmodule