//SystemVerilog
module gray_converter #(parameter WIDTH=8) (
    input [WIDTH-1:0] bin_in,
    input bin_to_gray,
    output reg [WIDTH-1:0] result
);
    // 声明临时变量用于格雷码到二进制转换
    reg [WIDTH-1:0] gray_to_bin_temp;
    
    // 优化实现，减少循环结构，使用并行赋值以改善时序和面积
    always @(*) begin
        if (bin_to_gray) begin
            // 二进制到格雷码转换
            result = bin_in ^ (bin_in >> 1);
        end
        else begin
            // 格雷码到二进制转换 - 使用并行计算替代循环
            gray_to_bin_temp[WIDTH-1] = bin_in[WIDTH-1];
            
            // 展开循环，并行计算
            if (WIDTH > 1) gray_to_bin_temp[WIDTH-2] = bin_in[WIDTH-2] ^ bin_in[WIDTH-1];
            if (WIDTH > 2) gray_to_bin_temp[WIDTH-3] = bin_in[WIDTH-3] ^ gray_to_bin_temp[WIDTH-2];
            if (WIDTH > 3) gray_to_bin_temp[WIDTH-4] = bin_in[WIDTH-4] ^ gray_to_bin_temp[WIDTH-3];
            if (WIDTH > 4) gray_to_bin_temp[WIDTH-5] = bin_in[WIDTH-5] ^ gray_to_bin_temp[WIDTH-4];
            if (WIDTH > 5) gray_to_bin_temp[WIDTH-6] = bin_in[WIDTH-6] ^ gray_to_bin_temp[WIDTH-5];
            if (WIDTH > 6) gray_to_bin_temp[WIDTH-7] = bin_in[WIDTH-7] ^ gray_to_bin_temp[WIDTH-6];
            if (WIDTH > 7) gray_to_bin_temp[0] = bin_in[0] ^ gray_to_bin_temp[1];
            
            result = gray_to_bin_temp;
        end
    end
endmodule