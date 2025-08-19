//SystemVerilog
// 重组的数据流分级处理的解复用器FSM
module Demux_FSM #(
    parameter DW = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [1:0]       state,
    input  wire [DW-1:0]    data,
    output reg  [3:0][DW-1:0] out
);
    // 状态定义
    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10; 
    localparam S3 = 2'b11;
    
    // 流水线级：第一级 - 数据和状态寄存
    reg [1:0]     state_r;
    reg [DW-1:0]  data_r;
    
    // 流水线第一级：捕获输入
    always @(posedge clk) begin
        if (rst) begin
            state_r <= 2'b00;
            data_r  <= {DW{1'b0}};
        end else begin
            state_r <= state;
            data_r  <= data;
        end
    end
    
    // 流水线第二级：状态解码和数据路由
    reg [3:0] channel_select;
    reg [DW-1:0] data_staged;
    
    always @(posedge clk) begin
        if (rst) begin
            channel_select <= 4'b0000;
            data_staged <= {DW{1'b0}};
        end else begin
            // 状态解码为独热码选择信号
            channel_select <= 4'b0000;
            case (state_r)
                S0: channel_select[0] <= 1'b1;
                S1: channel_select[1] <= 1'b1;
                S2: channel_select[2] <= 1'b1;
                S3: channel_select[3] <= 1'b1;
            endcase
            
            // 将数据存入中间寄存器
            data_staged <= data_r;
        end
    end
    
    // 流水线第三级：输出寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            out[0] <= {DW{1'b0}};
            out[1] <= {DW{1'b0}};
            out[2] <= {DW{1'b0}};
            out[3] <= {DW{1'b0}};
        end else begin
            // 有条件地更新每个输出通道
            if (channel_select[0]) out[0] <= data_staged;
            if (channel_select[1]) out[1] <= data_staged;
            if (channel_select[2]) out[2] <= data_staged;
            if (channel_select[3]) out[3] <= data_staged;
        end
    end
endmodule