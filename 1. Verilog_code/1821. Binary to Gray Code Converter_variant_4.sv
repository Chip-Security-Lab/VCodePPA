//SystemVerilog
module bin2gray_converter #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // 使用借位减法器算法实现格雷码转换
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] diff;
    
    // 最低位直接赋值
    assign gray_out[0] = bin_in[0];
    
    // 借位减法器实现
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gray_gen
            assign borrow[i] = ~bin_in[i-1];
            assign diff[i] = bin_in[i] ^ borrow[i];
            assign gray_out[i] = diff[i];
        end
    endgenerate
endmodule