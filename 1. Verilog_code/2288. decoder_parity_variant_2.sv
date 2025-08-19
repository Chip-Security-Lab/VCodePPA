//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005 Verilog标准

// 顶层模块
module decoder_parity (
    input clk,               // 时钟信号
    input rst_n,             // 复位信号，低电平有效
    input [4:0] addr_in,     // [4]=parity
    input valid_in,          // 输入有效信号
    output ready_out,        // 输出就绪信号
    output valid_out,        // 输出有效信号
    input ready_in,          // 输入就绪信号
    output [7:0] decoded     // 解码后的数据
);
    wire parity_bit;
    wire [3:0] addr;
    wire parity_match;
    wire internal_valid;
    reg processed;           // 数据处理状态
    
    // 分配输入地址和奇偶校验位
    assign addr = addr_in[3:0];
    assign parity_bit = addr_in[4];
    
    // 输出就绪信号，表示模块可以接收新数据
    assign ready_out = ready_in || !processed;
    
    // 数据处理状态管理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            processed <= 1'b0;
        else if (valid_in && ready_out)
            processed <= 1'b1;
        else if (valid_out && ready_in)
            processed <= 1'b0;
    end
    
    // 实例化奇偶校验计算模块
    parity_calculator parity_calc_inst (
        .data(addr),
        .parity(parity_match)
    );
    
    // 实例化有效性检查模块
    validity_checker validity_check_inst (
        .parity_bit(parity_bit),
        .computed_parity(parity_match),
        .valid(internal_valid)
    );
    
    // 输出有效信号生成
    assign valid_out = processed && internal_valid;
    
    // 实例化解码器模块
    address_decoder addr_decoder_inst (
        .addr(addr),
        .valid(internal_valid),
        .decoded(decoded)
    );
    
endmodule

// 奇偶校验计算模块
module parity_calculator (
    input [3:0] data,
    output parity
);
    // 计算数据的奇偶校验
    assign parity = ^data;
endmodule

// 有效性检查模块
module validity_checker (
    input parity_bit,
    input computed_parity,
    output reg valid
);
    // 检查计算的奇偶校验是否与提供的奇偶校验位匹配
    always @(*) begin
        valid = (computed_parity == parity_bit);
    end
endmodule

// 地址解码器模块
module address_decoder (
    input [3:0] addr,
    input valid,
    output [7:0] decoded
);
    // 当有效时执行地址解码
    assign decoded = valid ? (1'b1 << addr) : 8'h0;
endmodule