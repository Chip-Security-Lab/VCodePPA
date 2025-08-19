//SystemVerilog
// 顶层模块
module Demux_AutoPipe #(parameter DW=8, AW=2) (
    input wire clk, rst,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] din,
    output wire [(1<<AW)-1:0][DW-1:0] dout
);
    // 定义本地参数提高可读性
    localparam NUM_OUTPUTS = 1<<AW;
    
    // 内部连接信号
    wire [NUM_OUTPUTS-1:0][DW-1:0] demux_out;
    
    // 实例化地址解码器子模块
    AddressDecoder #(
        .DW(DW),
        .AW(AW)
    ) addr_decoder (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .din(din),
        .demux_out(demux_out)
    );
    
    // 实例化输出寄存器子模块
    OutputRegister #(
        .DW(DW),
        .AW(AW)
    ) output_reg (
        .clk(clk),
        .rst(rst),
        .pipe_reg(demux_out),
        .dout(dout)
    );
    
endmodule

// 地址解码器子模块 - 负责根据地址将输入数据路由到正确的内部寄存器
module AddressDecoder #(parameter DW=8, AW=2) (
    input wire clk, rst,
    input wire [AW-1:0] addr,
    input wire [DW-1:0] din,
    output reg [(1<<AW)-1:0][DW-1:0] demux_out
);
    // 定义本地参数
    localparam NUM_OUTPUTS = 1<<AW;
    
    integer i;
    always @(posedge clk) begin
        if(rst) begin
            // 重置所有寄存器
            for(i = 0; i < NUM_OUTPUTS; i = i + 1) begin
                demux_out[i] <= {DW{1'b0}};
            end
        end else begin
            // 只更新被寻址的特定寄存器
            for(i = 0; i < NUM_OUTPUTS; i = i + 1) begin
                if(i == addr)
                    demux_out[i] <= din;
            end
        end
    end
endmodule

// 输出寄存器子模块 - 负责对解码后的数据进行缓冲并输出
module OutputRegister #(parameter DW=8, AW=2) (
    input wire clk, rst,
    input wire [(1<<AW)-1:0][DW-1:0] pipe_reg,
    output reg [(1<<AW)-1:0][DW-1:0] dout
);
    // 定义本地参数
    localparam NUM_OUTPUTS = 1<<AW;
    
    integer i;
    always @(posedge clk) begin
        if(rst) begin
            // 重置所有输出寄存器
            for(i = 0; i < NUM_OUTPUTS; i = i + 1) begin
                dout[i] <= {DW{1'b0}};
            end
        end else begin
            // 并行将数据传输到输出寄存器
            for(i = 0; i < NUM_OUTPUTS; i = i + 1) begin
                dout[i] <= pipe_reg[i];
            end
        end
    end
endmodule