//SystemVerilog

//-----------------------------------------------------------------------------
// OneHotEncoder
// 功能: 根据地址输入生成 one-hot 编码输出
//-----------------------------------------------------------------------------
module OneHotEncoder #(
    parameter OUTPUT_COUNT = 8,
    parameter ADDR_WIDTH = 3
) (
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [OUTPUT_COUNT-1:0] one_hot
);
    genvar i;
    generate
        for (i = 0; i < OUTPUT_COUNT; i = i + 1) begin : gen_one_hot
            assign one_hot[i] = (addr == i[ADDR_WIDTH-1:0]) ? 1'b1 : 1'b0;
        end
    endgenerate
endmodule

//-----------------------------------------------------------------------------
// AddrMinusOne
// 功能: 计算 addr - 1（补码实现）
//-----------------------------------------------------------------------------
module AddrMinusOne #(
    parameter ADDR_WIDTH = 3
) (
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [ADDR_WIDTH-1:0] addr_minus_one
);
    wire [ADDR_WIDTH-1:0] inverted_addr;
    wire [ADDR_WIDTH-1:0] one_const;

    assign inverted_addr = ~addr;
    assign one_const = {{(ADDR_WIDTH-1){1'b0}}, 1'b1}; // 等价于 3'b001
    assign addr_minus_one = inverted_addr + one_const;
endmodule

//-----------------------------------------------------------------------------
// ParamDemux
// 顶层模块：参数化多路分配器，实例化功能子模块
//-----------------------------------------------------------------------------
module param_demux #(
    parameter OUTPUT_COUNT = 8,         // 输出线数量
    parameter ADDR_WIDTH = 3            // 地址宽度(log2(outputs))
) (
    input  wire data_input,                     // 单一数据输入
    input  wire [ADDR_WIDTH-1:0] addr,          // 地址选择
    output wire [OUTPUT_COUNT-1:0] out          // 多路输出
);
    // 内部信号
    wire [OUTPUT_COUNT-1:0] one_hot_mask;
    wire [ADDR_WIDTH-1:0] addr_minus_one;

    // 子模块：地址减一
    AddrMinusOne #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_addr_minus_one (
        .addr(addr),
        .addr_minus_one(addr_minus_one)
    );

    // 子模块：one-hot 编码
    OneHotEncoder #(
        .OUTPUT_COUNT(OUTPUT_COUNT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_one_hot_encoder (
        .addr(addr),
        .one_hot(one_hot_mask)
    );

    // 输出控制
    assign out = data_input ? one_hot_mask : {OUTPUT_COUNT{1'b0}};
endmodule