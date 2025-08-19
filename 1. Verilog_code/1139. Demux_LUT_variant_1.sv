//SystemVerilog
// 顶层模块
module Demux_LUT #(
    parameter DW = 8,        // 数据宽度
    parameter AW = 3,        // 地址宽度
    parameter LUT_SIZE = 8   // 查找表大小
)(
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output [LUT_SIZE-1:0][DW-1:0] data_out
);

    // 内部连线
    wire [AW-1:0] actual_addr;
    
    // 实例化地址重映射子模块
    Address_Remapper #(
        .AW(AW),
        .LUT_SIZE(LUT_SIZE)
    ) addr_remapper (
        .addr(addr),
        .remap_table(remap_table),
        .actual_addr(actual_addr)
    );
    
    // 实例化数据分配子模块
    Data_Distributor #(
        .DW(DW),
        .AW(AW),
        .LUT_SIZE(LUT_SIZE)
    ) data_distributor (
        .data_in(data_in),
        .actual_addr(actual_addr),
        .data_out(data_out)
    );
    
endmodule

// 地址重映射子模块
module Address_Remapper #(
    parameter AW = 3,
    parameter LUT_SIZE = 8
)(
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output [AW-1:0] actual_addr
);
    
    // 使用查找表进行地址重映射
    assign actual_addr = remap_table[addr];
    
endmodule

// 数据分配子模块
module Data_Distributor #(
    parameter DW = 8,
    parameter AW = 3,
    parameter LUT_SIZE = 8
)(
    input [DW-1:0] data_in,
    input [AW-1:0] actual_addr,
    output [LUT_SIZE-1:0][DW-1:0] data_out
);
    
    // 优化后的地址解码逻辑
    reg [LUT_SIZE-1:0] select_line;
    
    always @(*) begin
        select_line = {LUT_SIZE{1'b0}};
        if (actual_addr < LUT_SIZE) begin
            select_line[actual_addr] = 1'b1;
        end
    end
    
    // 基于优化后的选择线分配数据
    genvar i;
    generate
        for (i = 0; i < LUT_SIZE; i = i + 1) begin : gen_outputs
            assign data_out[i] = select_line[i] ? data_in : {DW{1'b0}};
        end
    endgenerate
    
endmodule