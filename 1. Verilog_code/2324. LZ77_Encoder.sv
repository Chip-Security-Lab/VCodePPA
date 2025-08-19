module LZ77_Encoder #(WIN_SIZE=4) (
    input clk, en,
    input [7:0] data,
    output reg [15:0] code
);
reg [7:0] buffer [0:WIN_SIZE-1];
reg [3:0] ptr;
integer i;

initial begin
    ptr = 0;
    for(i=0; i<WIN_SIZE; i=i+1)
        buffer[i] = 0;
end

always @(posedge clk) begin
    if (en) begin
        code <= 16'h0; // 默认值
        
        for(i=0; i<WIN_SIZE; i=i+1) begin
            if(buffer[i] == data) begin
                code <= {i[3:0], 8'h0};
            end
        end
        
        // 移位缓冲区
        for(i=WIN_SIZE-1; i>0; i=i-1)
            buffer[i] <= buffer[i-1];
        buffer[0] <= data;
    end
end
endmodule