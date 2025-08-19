//SystemVerilog
module dynamic_endian #(parameter WIDTH=32) (
    input [WIDTH-1:0] data_in,
    input reverse_en,
    output reg [WIDTH-1:0] data_out
);
    // 8位查找表用于位翻转
    reg [7:0] reverse_lut [0:255];
    reg [WIDTH-1:0] temp_data;
    integer i, j;
    
    // 初始化查找表
    initial begin
        for (i=0; i<256; i=i+1) begin
            reverse_lut[i] = 0;
            for (j=0; j<8; j=j+1) begin
                reverse_lut[i][j] = (i >> (7-j)) & 1'b1;
            end
        end
    end
    
    always @(*) begin
        if (reverse_en) begin
            // 使用查找表进行8位一组的位翻转
            for (i=0; i<WIDTH; i=i+8) begin
                if (i+8 <= WIDTH) begin
                    temp_data[i+:8] = reverse_lut[data_in[WIDTH-i-8+:8]];
                end else begin
                    // 处理不是8位整数倍的剩余位
                    for (j=i; j<WIDTH; j=j+1) begin
                        temp_data[j] = data_in[WIDTH-1-j];
                    end
                end
            end
            data_out = temp_data;
        end else begin
            data_out = data_in;
        end
    end
endmodule