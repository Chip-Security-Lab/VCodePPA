//SystemVerilog
module Demux_LUT #(parameter DW=8, AW=3, LUT_SIZE=8) (
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output [LUT_SIZE-1:0][DW-1:0] data_out
);
    wire [AW-1:0] actual_addr;
    wire [LUT_SIZE-1:0] select_lines;
    
    // 使用先行进位加法器算法实现地址转换
    LookAheadAddressMapper #(
        .AW(AW),
        .LUT_SIZE(LUT_SIZE)
    ) addr_mapper (
        .addr(addr),
        .remap_table(remap_table),
        .actual_addr(actual_addr)
    );
    
    // 为每个输出生成选择信号
    genvar i;
    generate
        for (i = 0; i < LUT_SIZE; i = i + 1) begin : gen_select
            assign select_lines[i] = (i == actual_addr) && (actual_addr < LUT_SIZE);
        end
    endgenerate
    
    // 明确的多路复用器实现
    generate
        for (i = 0; i < LUT_SIZE; i = i + 1) begin : gen_outputs
            assign data_out[i] = select_lines[i] ? data_in : {DW{1'b0}};
        end
    endgenerate
endmodule

// 使用先行进位加法器算法实现的地址映射模块
module LookAheadAddressMapper #(parameter AW=3, LUT_SIZE=8) (
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output reg [AW-1:0] actual_addr
);
    // 进位生成和传播信号
    wire [AW-1:0] g, p;
    wire [AW:0] c;
    
    // 先查找基础地址
    wire [AW-1:0] base_addr = remap_table[addr[AW-1:0]];
    
    // 先行进位加法器实现
    // 初始进位为0
    assign c[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < AW; i = i + 1) begin : gen_gp
            // 生成进位生成和传播信号
            assign g[i] = base_addr[i] & addr[i];
            assign p[i] = base_addr[i] ^ addr[i];
            
            // 计算每一位的进位
            if (i == 0) begin
                assign c[i+1] = g[i];
            end
            else if (i == 1) begin
                assign c[i+1] = g[i] | (p[i] & g[i-1]);
            end
            else if (i == 2) begin
                assign c[i+1] = g[i] | (p[i] & g[i-1]) | (p[i] & p[i-1] & g[i-2]);
            end
            else begin
                assign c[i+1] = g[i] | (p[i] & c[i]);
            end
        end
    endgenerate
    
    // 计算最终地址
    always @(*) begin
        actual_addr = base_addr ^ p ^ {c[AW:1]};
        
        // 确保地址在有效范围内
        if (actual_addr >= LUT_SIZE) begin
            actual_addr = base_addr;
        end
    end
endmodule