module BWT_Compress #(BLK=8) (
    input clk, en,
    input [BLK*8-1:0] data_in,
    output reg [BLK*8-1:0] data_out
);
reg [7:0] buffer [0:BLK-1];
reg [7:0] sorted [0:BLK-1];
integer i, j;
reg [7:0] temp;

always @(posedge clk) begin
    if(en) begin
        // 提取数据到buffer
        for(i=0; i<BLK; i=i+1)
            buffer[i] = data_in[i*8 +: 8];
            
        // 复制到排序数组
        for(i=0; i<BLK; i=i+1)
            sorted[i] = buffer[i];
            
        // 实现简单的冒泡排序
        for(i=0; i<BLK-1; i=i+1) begin
            for(j=0; j<BLK-1-i; j=j+1) begin
                if(sorted[j] > sorted[j+1]) begin
                    temp = sorted[j];
                    sorted[j] = sorted[j+1];
                    sorted[j+1] = temp;
                end
            end
        end
        
        // 组装输出数据
        data_out[7:0] = sorted[BLK-1];
        for(i=1; i<BLK; i=i+1)
            data_out[i*8 +: 8] = sorted[i-1];
    end
end
endmodule