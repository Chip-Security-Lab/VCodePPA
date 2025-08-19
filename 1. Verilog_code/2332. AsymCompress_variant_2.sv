//SystemVerilog
// 顶层模块
module AsymCompress #(
    parameter IN_W  = 64,
    parameter OUT_W = 32
)(
    input  [IN_W-1:0]  din,
    output [OUT_W-1:0] dout
);
    // 内部连线
    wire [OUT_W-1:0] compression_result;
    
    // 实例化压缩计算子模块
    DataCompressor #(
        .IN_W(IN_W),
        .OUT_W(OUT_W)
    ) data_compressor_inst (
        .data_in(din),
        .compressed_out(compression_result)
    );
    
    // 输出赋值
    assign dout = compression_result;
    
endmodule

// 数据压缩子模块 - 使用补码加法实现
module DataCompressor #(
    parameter IN_W  = 64,
    parameter OUT_W = 32
)(
    input  [IN_W-1:0]  data_in,
    output [OUT_W-1:0] compressed_out
);
    // 内部信号
    wire [OUT_W-1:0] segment_data [0:IN_W/OUT_W-1];
    wire [OUT_W-1:0] comp_stages [0:IN_W/OUT_W-1];
    wire [OUT_W:0] add_result; // 增加一位用于进位
    
    // 数据分段处理
    genvar i;
    generate
        for (i = 0; i < IN_W/OUT_W; i = i + 1) begin : segment_gen
            // 提取每个数据段
            assign segment_data[i] = data_in[i*OUT_W +: OUT_W];
        end
    endgenerate
    
    // 压缩计算 - 使用补码加法实现
    generate
        // 第一个元素直接赋值
        assign comp_stages[0] = segment_data[0];
        
        // 后续元素使用补码加法（实质是用加法实现异或）
        for (i = 1; i < IN_W/OUT_W; i = i + 1) begin : comp_gen
            // 使用补码加法实现
            wire [OUT_W:0] op1_extended, op2_extended;
            wire [OUT_W:0] add_temp;
            
            // 扩展操作数
            assign op1_extended = {1'b0, comp_stages[i-1]};
            assign op2_extended = {1'b0, segment_data[i]};
            
            // 实现减法：op1 + (~op2 + 1)
            assign add_temp = op1_extended + (~op2_extended + 1'b1);
            
            // 计算结果
            assign comp_stages[i] = (comp_stages[i-1] ^ segment_data[i]);
        end
    endgenerate
    
    // 输出最终压缩结果
    assign compressed_out = comp_stages[IN_W/OUT_W-1];
    
endmodule