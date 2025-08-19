//SystemVerilog
module Comparator_Window #(
    parameter WIDTH = 10
)(
    input wire                 clk,       // 时钟信号
    input wire                 rst_n,     // 复位信号，低有效
    input wire  [WIDTH-1:0]    data_in,   // 输入数据
    input wire  [WIDTH-1:0]    low_th,    // 下阈值
    input wire  [WIDTH-1:0]    high_th,   // 上阈值
    output reg                 in_range   // 范围指示输出
);

    // 优化后的流水线寄存器
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] low_th_reg;
    reg [WIDTH-1:0] high_th_reg;
    
    // 优化后的比较逻辑
    wire range_check;
    
    // 单级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {WIDTH{1'b0}};
            low_th_reg  <= {WIDTH{1'b0}};
            high_th_reg <= {WIDTH{1'b0}};
        end else begin
            data_in_reg <= data_in;
            low_th_reg  <= low_th;
            high_th_reg <= high_th;
        end
    end
    
    // 组合逻辑比较
    assign range_check = (data_in_reg >= low_th_reg) && (data_in_reg <= high_th_reg);
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range <= 1'b0;
        end else begin
            in_range <= range_check;
        end
    end

endmodule