//SystemVerilog
// 顶层模块 - 多通道奇偶校验生成器
module multi_channel_parity #(
    parameter CHANNELS = 4,
    parameter WIDTH = 8
)(
    input [CHANNELS*WIDTH-1:0] ch_data,
    output [CHANNELS-1:0] ch_parity
);
    // 实例化多个单通道奇偶校验生成器
    genvar i;
    generate
        for (i=0; i<CHANNELS; i=i+1) begin : gen_parity_channels
            wire [WIDTH-1:0] data_slice;
            
            // 提取每个通道的数据
            data_extractor #(
                .WIDTH(WIDTH)
            ) data_extractor_inst (
                .full_data(ch_data),
                .channel_idx(i),
                .channel_data(data_slice)
            );
            
            // 计算单通道的奇偶校验
            single_channel_parity #(
                .WIDTH(WIDTH)
            ) parity_gen_inst (
                .data(data_slice),
                .parity(ch_parity[i])
            );
        end
    endgenerate
endmodule

// 子模块 - 数据提取器
module data_extractor #(
    parameter WIDTH = 8
)(
    input [(WIDTH*32)-1:0] full_data,  // 支持最多32个通道
    input [4:0] channel_idx,          // 通道索引
    output [WIDTH-1:0] channel_data    // 提取的通道数据
);
    assign channel_data = full_data[channel_idx*WIDTH +: WIDTH];
endmodule

// 子模块 - 单通道奇偶校验计算
module single_channel_parity #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    output parity
);
    // 奇偶校验计算的两种实现方法
    
    // 方法1: 使用异或归约运算符（保持原有实现）
    assign parity = ^data;
    
    /*
    // 方法2: 使用循环计算 (可选的替代实现)
    // reg parity_bit;
    // integer j;
    // always @(*) begin
    //     parity_bit = 1'b0;
    //     for (j=0; j<WIDTH; j=j+1)
    //         parity_bit = parity_bit ^ data[j];
    // end
    // assign parity = parity_bit;
    */
endmodule