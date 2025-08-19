module WindowMax #(parameter W=8, MAX_WIN=5) (
    input clk,
    input [3:0] win_size,
    input [W-1:0] din,
    output reg [W-1:0] max_val
);
    reg [W-1:0] buffer [0:MAX_WIN-1];
    reg [W-1:0] temp_max;
    integer i;
    
    always @(posedge clk) begin
        // 手动移位缓冲区
        for(i=MAX_WIN-1; i>0; i=i-1)
            buffer[i] <= buffer[i-1];
        buffer[0] <= din;
        
        // 查找最大值
        temp_max = buffer[0];
        for(i=1; i<MAX_WIN; i=i+1)
            if(i < win_size && buffer[i] > temp_max) temp_max = buffer[i];
        max_val <= temp_max;
    end
endmodule