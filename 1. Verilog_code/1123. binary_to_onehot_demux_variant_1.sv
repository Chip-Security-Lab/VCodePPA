//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: binary_to_onehot_demux
// Description: 将二进制地址转换为单热码输出并选择性传递输入数据
// Author: Restructured by Claude
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module binary_to_onehot_demux (
    input  wire        data_in,      // 输入数据
    input  wire [2:0]  binary_addr,  // 二进制地址
    output wire [7:0]  one_hot_out   // 单热码输出与数据
);
    // 内部信号连接
    wire [7:0] decoder_out;          // 解码后的地址
    
    // 实例化地址解码器子模块
    binary_decoder u_decoder (
        .binary_addr  (binary_addr),
        .one_hot_addr (decoder_out)
    );
    
    // 实例化数据分配器子模块
    data_distributor u_distributor (
        .data_in      (data_in),
        .decoder_out  (decoder_out),
        .one_hot_out  (one_hot_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: binary_decoder
// Description: 将二进制地址转换为单热码格式
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module binary_decoder #(
    parameter ADDR_WIDTH = 3,
    parameter OUT_WIDTH = 8
) (
    input  wire [ADDR_WIDTH-1:0] binary_addr,  // 二进制地址输入
    output reg  [OUT_WIDTH-1:0]  one_hot_addr  // 单热码地址输出
);
    // 地址解码逻辑 - 将二进制地址转换为单热码
    always @(*) begin
        one_hot_addr = {OUT_WIDTH{1'b0}};
        one_hot_addr[binary_addr] = 1'b1;
    end
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: data_distributor
// Description: 根据解码后的地址将输入数据分配到对应输出线
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module data_distributor #(
    parameter WIDTH = 8
) (
    input  wire              data_in,     // 输入数据位
    input  wire [WIDTH-1:0]  decoder_out, // 解码后的地址
    output wire [WIDTH-1:0]  one_hot_out  // 输出数据
);
    // 数据选择逻辑 - 将输入数据应用到选中的输出线
    assign one_hot_out = {WIDTH{data_in}} & decoder_out;
endmodule