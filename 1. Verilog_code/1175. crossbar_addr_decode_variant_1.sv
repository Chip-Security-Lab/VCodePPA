//SystemVerilog
// 顶层模块
module crossbar_addr_decode #(
    parameter AW = 4,  // 地址宽度
    parameter DW = 16, // 数据宽度 
    parameter N  = 8   // 输出端口数量
)(
    input               clk,
    input  [DW-1:0]     data_in,
    input  [AW-1:0]     addr,
    output [N*DW-1:0]   data_out
);

    // 内部连线
    wire [N-1:0] sel;

    // 实例化地址解码器子模块
    addr_decoder #(
        .AW(AW),
        .N(N)
    ) addr_decoder_inst (
        .addr(addr),
        .sel(sel)
    );

    // 实例化数据分发器子模块
    data_distributor #(
        .DW(DW),
        .N(N)
    ) data_distributor_inst (
        .data_in(data_in),
        .sel(sel),
        .data_out(data_out)
    );

endmodule

// 地址解码器子模块 - 使用条件求和减法算法实现
module addr_decoder #(
    parameter AW = 4,   // 地址宽度
    parameter N  = 8    // 选择信号数量
)(
    input  [AW-1:0] addr,
    output reg [N-1:0] sel
);
    // 条件求和减法算法实现比较
    reg [7:0] comp_result;
    reg [7:0] borrow;
    reg comp_valid;
    
    always @(*) begin
        sel = {N{1'b0}};  // 初始化为全0
        
        // 使用条件求和减法算法实现比较addr < N
        borrow[0] = 1'b0;
        comp_result[0] = addr[0] ^ 1'b0 ^ borrow[0];
        borrow[1] = (~addr[0] & borrow[0]) | (~addr[0] & 1'b0) | (borrow[0] & 1'b0);
        
        comp_result[1] = addr[1] ^ N[1] ^ borrow[1];
        borrow[2] = (~addr[1] & borrow[1]) | (~addr[1] & N[1]) | (borrow[1] & N[1]);
        
        comp_result[2] = addr[2] ^ N[2] ^ borrow[2];
        borrow[3] = (~addr[2] & borrow[2]) | (~addr[2] & N[2]) | (borrow[2] & N[2]);
        
        comp_result[3] = addr[3] ^ N[3] ^ borrow[3];
        borrow[4] = (~addr[3] & borrow[3]) | (~addr[3] & N[3]) | (borrow[3] & N[3]);
        
        comp_result[4] = 1'b0 ^ N[4] ^ borrow[4];
        borrow[5] = (~1'b0 & borrow[4]) | (~1'b0 & N[4]) | (borrow[4] & N[4]);
        
        comp_result[5] = 1'b0 ^ N[5] ^ borrow[5];
        borrow[6] = (~1'b0 & borrow[5]) | (~1'b0 & N[5]) | (borrow[5] & N[5]);
        
        comp_result[6] = 1'b0 ^ N[6] ^ borrow[6];
        borrow[7] = (~1'b0 & borrow[6]) | (~1'b0 & N[6]) | (borrow[6] & N[6]);
        
        comp_result[7] = 1'b0 ^ N[7] ^ borrow[7];
        
        comp_valid = ~borrow[7]; // 如果没有借位，则addr < N
        
        // 根据比较结果设置选择信号
        if(comp_valid) sel[addr] = 1'b1;
    end

endmodule

// 数据分发器子模块
module data_distributor #(
    parameter DW = 16,  // 数据宽度
    parameter N  = 8    // 输出端口数量
)(
    input  [DW-1:0]    data_in,
    input  [N-1:0]     sel,
    output [N*DW-1:0]  data_out
);

    genvar g;
    generate 
        for(g=0; g<N; g=g+1) begin: gen_out
            // 基于选择信号分发数据到对应端口
            assign data_out[(g*DW) +: DW] = sel[g] ? data_in : {DW{1'b0}};
        end
    endgenerate

endmodule