module SobelEdge #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W+1:0] gradient
);
    reg [W-1:0] window [0:8];
    integer i;
    
    always @(posedge clk) begin
        // 手动移位窗口
        for(i=8; i>0; i=i-1)
            window[i] <= window[i-1];
        window[0] <= pixel_in;
        
        // 计算梯度
        gradient <= (window[0] + (window[3] << 1) + window[6]) - 
                   (window[2] + (window[5] << 1) + window[8]);
    end
endmodule