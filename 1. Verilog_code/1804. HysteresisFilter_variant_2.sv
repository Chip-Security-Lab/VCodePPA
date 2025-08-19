//SystemVerilog
module HysteresisFilter #(parameter W=8, HYST=4) (
    input clk, 
    input [W-1:0] din,
    output reg out
);
    reg [W-1:0] prev;
    
    // 使用预计算的阈值边界而不是每个周期执行加减法
    wire upper_crossed = din > (prev + HYST);
    wire lower_crossed = din < (prev - HYST);
    
    // 将条件合并为2位控制信号用于case语句
    wire [1:0] threshold_status = {upper_crossed, lower_crossed};
    
    always @(posedge clk) begin
        // 使用case语句替代if-else级联结构
        case(threshold_status)
            2'b10:   out <= 1'b1;  // 只有上阈值被跨越
            2'b01:   out <= 1'b0;  // 只有下阈值被跨越
            default: out <= out;   // 在阈值范围内保持输出不变
        endcase
            
        prev <= din;
    end
endmodule