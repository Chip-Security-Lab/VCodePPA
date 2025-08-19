module manchester_encoder (
    input clk, rst, 
    input data_in,
    output reg encoded
);
    reg clk_div;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 0;
            clk_div <= 0;
        end else begin
            clk_div <= ~clk_div; // 将时钟频率除以2
            encoded <= data_in ^ clk_div; // 曼彻斯特编码
        end
    end
endmodule