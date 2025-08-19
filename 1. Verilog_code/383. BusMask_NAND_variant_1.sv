//SystemVerilog
///////////////////////////////////////////
// File: BusMask_NAND_Top.v
// 顶层模块：整合掩码逻辑子模块和条件求和减法器
///////////////////////////////////////////
module BusMask_NAND_Top #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] res,
    // 新增减法器接口
    input [7:0] minuend,
    input [7:0] subtrahend,
    output [7:0] difference
);
    wire [WIDTH-1:0] masked_data;
    
    // 实例化掩码子模块
    MaskOperation #(
        .WIDTH(WIDTH)
    ) mask_op_inst (
        .data_in(data),
        .mask_in(mask),
        .masked_data_out(masked_data)
    );
    
    // 实例化反相器子模块
    InverterOperation #(
        .WIDTH(WIDTH)
    ) inverter_inst (
        .data_in(masked_data),
        .inverted_data_out(res)
    );
    
    // 实例化条件求和减法器子模块
    ConditionalSumSubtractor #(
        .WIDTH(8)
    ) subtractor_inst (
        .minuend(minuend),
        .subtrahend(subtrahend),
        .difference(difference)
    );
    
endmodule

///////////////////////////////////////////
// File: MaskOperation.v
// 子模块：执行位掩码操作
///////////////////////////////////////////
module MaskOperation #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_in,
    output [WIDTH-1:0] masked_data_out
);
    // 将掩码应用到数据上
    assign masked_data_out = data_in & mask_in;
    
endmodule

///////////////////////////////////////////
// File: InverterOperation.v
// 子模块：执行位反转操作
///////////////////////////////////////////
module InverterOperation #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] inverted_data_out
);
    // 对输入数据进行位反转
    assign inverted_data_out = ~data_in;
    
endmodule

///////////////////////////////////////////
// File: ConditionalSumSubtractor.v
// 子模块：使用条件求和算法实现的减法器
///////////////////////////////////////////
module ConditionalSumSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // 使用条件求和减法算法实现
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] complement;
    
    // 计算2的补码
    assign complement = ~subtrahend + 1'b1;
    
    // 初始进位为0
    assign carry[0] = 1'b0;
    
    // 生成条件求和逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_cond_sum
            wire p0, p1, g0, g1;
            wire sum0, sum1;
            
            // 计算两种可能的部分和和进位生成条件
            assign p0 = minuend[i] ^ complement[i];
            assign g0 = minuend[i] & complement[i];
            assign sum0 = p0 ^ carry[i];
            
            // 选择正确的和
            assign difference[i] = sum0;
            
            // 生成下一位的进位
            assign carry[i+1] = g0 | (p0 & carry[i]);
        end
    endgenerate
    
endmodule