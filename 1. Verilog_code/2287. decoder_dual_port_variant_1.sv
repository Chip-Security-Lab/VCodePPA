//SystemVerilog
`timescale 1ns / 1ps

module decoder_dual_port (
    input [3:0] rd_addr, wr_addr,
    output [15:0] rd_sel, wr_sel
);
    // 实例化读地址解码器
    address_decoder rd_decoder (
        .addr(rd_addr),
        .sel(rd_sel)
    );

    // 实例化写地址解码器
    address_decoder wr_decoder (
        .addr(wr_addr),
        .sel(wr_sel)
    );
endmodule

// 通用地址解码器子模块
module address_decoder (
    input [3:0] addr,
    output [15:0] sel
);
    // 参数化实现，提高可配置性
    parameter WIDTH = 4;
    parameter OUT_WIDTH = 16;
    
    // 使用移位操作实现解码
    assign sel = {{(OUT_WIDTH-1){1'b0}}, 1'b1} << addr;
endmodule