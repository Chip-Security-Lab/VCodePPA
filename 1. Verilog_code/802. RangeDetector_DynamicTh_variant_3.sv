//SystemVerilog
module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk, wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    output reg out_flag
);
    reg [WIDTH-1:0] current_low, current_high;
    reg [WIDTH-1:0] data_in_reg;
    wire in_range;
    
    // 优化：减少寄存器数量，移除不必要的current_low_reg和current_high_reg
    // 直接使用current_low和current_high进行比较
    
    always @(posedge clk) begin
        if(wr_en) begin
            current_low <= new_low;
            current_high <= new_high;
        end
        data_in_reg <= data_in;
        out_flag <= in_range;
    end
    
    // 优化：使用单个过程比较范围，避免冗余的AND操作
    // 使用先检查边界条件的方式优化检测逻辑
    assign in_range = (data_in_reg >= current_low) && (data_in_reg <= current_high);
    
endmodule