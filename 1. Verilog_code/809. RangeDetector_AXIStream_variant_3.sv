//SystemVerilog
module RangeDetector_AXIStream #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input tvalid,
    input [WIDTH-1:0] tdata,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg tvalid_out,
    output reg [WIDTH-1:0] tdata_out
);
    // 拆分范围检测为两个独立比较，减少关键路径长度
    reg greater_equal_lower, less_equal_upper;
    reg in_range;
    reg [WIDTH-1:0] data_reg;
    reg valid_reg;
    
    // 并行计算两个比较条件，缩短关键路径
    always @(*) begin
        greater_equal_lower = (tdata >= lower);
        less_equal_upper = (tdata <= upper);
        in_range = greater_equal_lower && less_equal_upper;
    end
    
    // 寄存输入数据和有效信号，减轻时序压力
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_reg <= {WIDTH{1'b0}};
            valid_reg <= 1'b0;
        end
        else begin
            data_reg <= tdata;
            valid_reg <= tvalid;
        end
    end
    
    // 更新输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_out <= 1'b0;
            tdata_out <= {WIDTH{1'b0}};
        end
        else begin
            tvalid_out <= valid_reg;
            tdata_out <= in_range ? data_reg : {WIDTH{1'b0}};
        end
    end
endmodule