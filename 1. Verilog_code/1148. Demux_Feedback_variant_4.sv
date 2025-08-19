//SystemVerilog
module Demux_Feedback #(
    parameter DW = 8
)(
    input                   clk,
    input      [DW-1:0]     data_in,
    input      [1:0]        sel,
    input      [3:0]        busy,
    output reg [3:0][DW-1:0] data_out
);
    // 阶段1: 输入捕获寄存器
    reg [DW-1:0] data_in_stage1;
    reg [1:0]    sel_stage1;
    reg [3:0]    busy_stage1;
    
    // 阶段2: 数据路径中间寄存器
    reg [DW-1:0] data_path;
    reg [1:0]    sel_path;
    reg          valid_path;
    
    // 阶段1: 输入捕获
    always @(posedge clk) begin
        data_in_stage1 <= data_in;
        sel_stage1     <= sel;
        busy_stage1    <= busy;
    end
    
    // 阶段2: 验证与数据准备
    always @(posedge clk) begin
        valid_path <= !busy_stage1[sel_stage1];
        data_path  <= data_in_stage1;
        sel_path   <= sel_stage1;
    end
    
    // 阶段3: 数据输出分配
    always @(posedge clk) begin
        // 默认清除所有输出
        data_out <= 4'b0;
        
        // 只在有效时写入对应通道
        if (valid_path) begin
            data_out[sel_path] <= data_path;
        end
    end
    
endmodule