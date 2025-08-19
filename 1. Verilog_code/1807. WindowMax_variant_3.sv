//SystemVerilog
module WindowMax #(parameter W=8, MAX_WIN=5) (
    input clk,
    input [3:0] win_size,
    input [W-1:0] din,
    output reg [W-1:0] max_val
);
    // 数据缓冲区
    reg [W-1:0] buffer [0:MAX_WIN-1];
    integer i;
    
    // 合并所有时钟上升沿触发的always块
    always @(posedge clk) begin
        // 移位缓冲区操作
        for(i=MAX_WIN-1; i>0; i=i-1)
            buffer[i] <= buffer[i-1];
        buffer[0] <= din;
        
        // 计算和更新最大值 (将组合逻辑直接整合到时序逻辑中)
        max_val <= buffer[0];
        for(i=1; i<MAX_WIN; i=i+1) begin
            if(i < win_size && buffer[i] > max_val)
                max_val <= buffer[i];
        end
    end
endmodule