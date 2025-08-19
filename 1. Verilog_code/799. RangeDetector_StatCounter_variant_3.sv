//SystemVerilog
module RangeDetector_StatCounter #(
    parameter WIDTH = 8,
    parameter CNT_WIDTH = 16
)(
    input clk, rst_n, clear,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] min_val,
    input [WIDTH-1:0] max_val,
    output reg [CNT_WIDTH-1:0] valid_count
);

    // 将范围检测逻辑拆分为独立比较，减少组合逻辑深度
    wire greater_equal_min = (data_in >= min_val);
    wire less_equal_max = (data_in <= max_val);
    
    // 寄存比较结果，减少关键路径长度
    reg greater_equal_min_reg, less_equal_max_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            greater_equal_min_reg <= 1'b0;
            less_equal_max_reg <= 1'b0;
        end
        else begin
            greater_equal_min_reg <= greater_equal_min;
            less_equal_max_reg <= less_equal_max;
        end
    end
    
    // 使用寄存的比较结果计算in_range
    wire in_range = greater_equal_min_reg && less_equal_max_reg;
    
    // 使用补码加法实现减法器
    wire [CNT_WIDTH-1:0] next_count;
    wire [CNT_WIDTH-1:0] neg_one = ~({CNT_WIDTH{1'b0}}) + 1'b1;  // -1的补码表示
    assign next_count = valid_count + neg_one + 1'b1;  // 等价于 valid_count + 1
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            valid_count <= {CNT_WIDTH{1'b0}};
        else if(clear) 
            valid_count <= {CNT_WIDTH{1'b0}};
        else if(in_range) 
            valid_count <= next_count;
    end

endmodule