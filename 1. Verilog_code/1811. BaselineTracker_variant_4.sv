//SystemVerilog
module BaselineTracker #(parameter W=8, TC=8'h10) (
    input clk,
    input [W-1:0] din,
    output [W-1:0] dout
);
    reg [W-1:0] baseline;
    reg [W-1:0] din_reg;
    reg compare_result;
    
    // 注册输入数据和比较结果
    always @(posedge clk) begin
        din_reg <= din;
        compare_result <= (din > baseline);
    end
    
    // 将baseline更新移动到比较结果之后
    always @(posedge clk) begin
        if (compare_result) begin
            baseline <= baseline + TC;
        end else begin
            baseline <= baseline - TC;
        end
    end
    
    // 使用注册后的输入进行减法操作
    assign dout = din_reg - baseline;
endmodule