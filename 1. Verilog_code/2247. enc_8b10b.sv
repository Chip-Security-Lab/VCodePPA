module enc_8b10b #(parameter K=0) (
    input [7:0] din,
    output reg [9:0] dout,
    input rd_in, // 改为输入参数
    output reg rd_out // 改为输出参数
);
    reg [5:0] disparity;
    
    always @(*) begin
        disparity = 6'd0;
        rd_out = rd_in;
        
        casez({K, din})
            9'b1_00011100: begin
                dout = 10'b0011111010;
                rd_out = (rd_in <= 0);
            end
            9'b0_10101010: begin
                dout = 10'b1010010111;
                disparity = 6'd2;
                rd_out = rd_in + disparity;
            end
            9'b0_00000000: begin
                dout = 10'b0101010101;
                disparity = 6'd0;
                rd_out = rd_in;
            end
            9'b0_11111111: begin
                dout = 10'b1010101010;
                disparity = 6'd0;
                rd_out = rd_in;
            end
            default: begin
                dout = 10'b0101010101; // 默认代码
                rd_out = rd_in;
            end
        endcase
    end
endmodule