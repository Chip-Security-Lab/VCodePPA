//SystemVerilog
// 顶层模块
module decoder_graycode #(
    parameter AW = 4
)(
    input [AW-1:0] bin_addr,
    output [2**AW-1:0] decoded
);
    // 内部连线
    wire [AW-1:0] gray_addr;
    
    // 实例化二进制到格雷码转换模块
    bin2gray #(
        .WIDTH(AW)
    ) bin2gray_conv (
        .binary_in(bin_addr),
        .gray_out(gray_addr)
    );
    
    // 实例化解码器模块
    gray_decoder #(
        .ADDR_WIDTH(AW)
    ) gray_dec (
        .gray_addr(gray_addr),
        .decoded_out(decoded)
    );
endmodule

// 二进制到格雷码转换子模块
module bin2gray #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] binary_in,
    output [WIDTH-1:0] gray_out
);
    assign gray_out = binary_in ^ {1'b0, binary_in[WIDTH-1:1]};
endmodule

// 格雷码解码器子模块，使用桶形移位器结构
module gray_decoder #(
    parameter ADDR_WIDTH = 4
)(
    input [ADDR_WIDTH-1:0] gray_addr,
    output [(2**ADDR_WIDTH)-1:0] decoded_out
);
    wire [(2**ADDR_WIDTH)-1:0] barrel_out;
    
    // 首先生成基础模式：仅最低位为1
    assign barrel_out = {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1};
    
    // 使用桶形移位器实现可变移位
    barrel_shifter #(
        .DATA_WIDTH(2**ADDR_WIDTH),
        .SHIFT_BITS(ADDR_WIDTH)
    ) barrel_shift_inst (
        .data_in(barrel_out),
        .shift_amount(gray_addr),
        .data_out(decoded_out)
    );
endmodule

// 桶形移位器实现
module barrel_shifter #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_BITS = 4
)(
    input [DATA_WIDTH-1:0] data_in,
    input [SHIFT_BITS-1:0] shift_amount,
    output [DATA_WIDTH-1:0] data_out
);
    // 为每个移位级别定义临时变量
    wire [DATA_WIDTH-1:0] shift_stage [SHIFT_BITS:0];
    
    // 初始数据
    assign shift_stage[0] = data_in;
    
    // 生成桶形移位器逻辑
    genvar i;
    generate
        for (i = 0; i < SHIFT_BITS; i = i + 1) begin : barrel_stage
            // 每级移位器处理 2^i 位移位
            assign shift_stage[i+1] = shift_amount[i] ? 
                                     {shift_stage[i][DATA_WIDTH-1-(2**i):0], 
                                      shift_stage[i][DATA_WIDTH-1:DATA_WIDTH-(2**i)]} :
                                     shift_stage[i];
        end
    endgenerate
    
    // 最终输出
    assign data_out = shift_stage[SHIFT_BITS];
endmodule