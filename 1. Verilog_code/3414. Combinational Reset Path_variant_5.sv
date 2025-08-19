//SystemVerilog
module RD4 #(
    parameter WIDTH = 4
)(
    input  wire             clk,       // 添加时钟输入以支持流水线结构
    input  wire             rst,       // 复位信号
    input  wire [WIDTH-1:0] in_data,   // 输入数据
    output reg  [WIDTH-1:0] out_data   // 输出数据 - 改为寄存器类型
);

    // 中间流水线级寄存器
    reg [WIDTH-1:0] data_stage1;
    
    // 第一级流水线 - 捕获输入数据
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= {WIDTH{1'b0}};
        end else begin
            data_stage1 <= in_data;
        end
    end
    
    // 第二级流水线 - 产生输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= {WIDTH{1'b0}};
        end else begin
            out_data <= data_stage1;
        end
    end

endmodule