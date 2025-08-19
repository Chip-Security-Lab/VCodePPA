//SystemVerilog
// Top module - decoder_graycode
module decoder_graycode #(
    parameter AW = 4
)(
    input wire [AW-1:0] bin_addr,
    output wire [2**AW-1:0] decoded
);
    wire [AW-1:0] gray_addr;
    
    // 实例化二进制到格雷码转换器
    bin2gray #(
        .WIDTH(AW)
    ) bin2gray_inst (
        .bin_in(bin_addr),
        .gray_out(gray_addr)
    );
    
    // 实例化格雷码解码器
    gray_decoder #(
        .ADDR_WIDTH(AW),
        .OUT_WIDTH(2**AW)
    ) gray_decoder_inst (
        .gray_addr(gray_addr),
        .decoded_out(decoded)
    );
    
endmodule

// 二进制到格雷码转换器子模块
module bin2gray #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // 使用移位和异或进行高效的二进制到格雷码转换
    assign gray_out = bin_in ^ (bin_in >> 1);
endmodule

// 格雷码解码器子模块 - 优化实现
module gray_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 16
)(
    input wire [ADDR_WIDTH-1:0] gray_addr,
    output wire [OUT_WIDTH-1:0] decoded_out
);
    // 对于不同的地址宽度预先计算移位量
    reg [OUT_WIDTH-1:0] out_reg;
    
    // 参数化的移位实现
    integer i;
    always @(*) begin
        // 初始化输出寄存器
        out_reg = {{(OUT_WIDTH-1){1'b0}}, 1'b1};
        
        // 使用累积移位方法优化位移操作
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin
            if (gray_addr[i]) begin
                out_reg = (out_reg << (1 << i)) | (out_reg >> (OUT_WIDTH - (1 << i)));
            end
        end
    end
    
    // 将寄存器连接到输出
    assign decoded_out = out_reg;
endmodule