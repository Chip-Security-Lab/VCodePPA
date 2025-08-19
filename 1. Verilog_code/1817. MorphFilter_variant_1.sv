//SystemVerilog
module MorphFilter #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W-1:0] pixel_out
);
    reg [W-1:0] window [0:7];  // 减少一个寄存器位置
    wire [W-1:0] morph_result;
    integer i;
    
    // 组合逻辑计算膨胀结果
    // 直接使用输入信号和窗口中的值计算结果
    assign morph_result = (pixel_in | window[2] | window[3]) ? 8'hFF : 8'h00;
    
    always @(posedge clk) begin
        // 移位窗口，减少了一级寄存
        for(i=7; i>0; i=i-1)
            window[i] <= window[i-1];
        window[0] <= pixel_in;
        
        // 输出寄存器
        pixel_out <= morph_result;
    end
endmodule