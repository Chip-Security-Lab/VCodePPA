//SystemVerilog
module RangeDetector_SyncEnRst #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output reg out_flag
);

reg [WIDTH-1:0] data_reg;
reg [WIDTH-1:0] lower_reg;
reg [WIDTH-1:0] upper_reg;

// 将比较操作拆分为两个单独的比较，减少关键路径长度
reg greater_equal_flag;  // 数据 >= 下界标志
reg less_equal_flag;     // 数据 <= 上界标志
reg range_valid_pipe;    // 流水线寄存器

// 第一级 - 寄存输入数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_reg <= {WIDTH{1'b0}};
        lower_reg <= {WIDTH{1'b0}};
        upper_reg <= {WIDTH{1'b0}};
    end
    else if(en) begin
        data_reg <= data_in;
        lower_reg <= lower_bound;
        upper_reg <= upper_bound;
    end
end

// 第二级 - 执行比较操作并存入流水线寄存器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        greater_equal_flag <= 1'b0;
        less_equal_flag <= 1'b0;
    end
    else if(en) begin
        greater_equal_flag <= (data_reg >= lower_reg);
        less_equal_flag <= (data_reg <= upper_reg);
    end
end

// 第三级 - 组合比较结果并输出
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        range_valid_pipe <= 1'b0;
        out_flag <= 1'b0;
    end
    else if(en) begin
        range_valid_pipe <= greater_equal_flag && less_equal_flag;
        out_flag <= range_valid_pipe;
    end
end

endmodule