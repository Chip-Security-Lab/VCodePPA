//SystemVerilog
// 顶层模块 - 控制整体BWT压缩流程
module BWT_Compress #(parameter BLK=8) (
    input clk, en,
    input [BLK*8-1:0] data_in,
    output reg [BLK*8-1:0] data_out
);
    // 内部信号
    wire [7:0] buffer [0:BLK-1];
    wire [7:0] sorted [0:BLK-1];
    
    // 数据提取子模块
    Data_Extractor #(
        .BLK(BLK)
    ) extractor (
        .data_in(data_in),
        .buffer(buffer)
    );
    
    // 排序处理子模块
    Sorter #(
        .BLK(BLK)
    ) sorter (
        .clk(clk),
        .en(en),
        .buffer(buffer),
        .sorted(sorted)
    );
    
    // 数据组装子模块
    Data_Assembler #(
        .BLK(BLK)
    ) assembler (
        .clk(clk),
        .en(en),
        .sorted(sorted),
        .data_out(data_out)
    );
    
endmodule

// 数据提取子模块 - 负责从输入数据流中提取字节
module Data_Extractor #(parameter BLK=8) (
    input [BLK*8-1:0] data_in,
    output [7:0] buffer [0:BLK-1]
);
    genvar i;
    generate
        for(i=0; i<BLK; i=i+1) begin: extract_loop
            assign buffer[i] = data_in[i*8 +: 8];
        end
    endgenerate
endmodule

// 排序处理子模块 - 实现数据排序功能
module Sorter #(parameter BLK=8) (
    input clk, en,
    input [7:0] buffer [0:BLK-1],
    output reg [7:0] sorted [0:BLK-1]
);
    integer i, j;
    reg [7:0] temp;
    reg [7:0] sort_array [0:BLK-1];
    
    always @(posedge clk) begin
        if(en) begin
            // 复制到排序数组
            for(i=0; i<BLK; i=i+1)
                sort_array[i] = buffer[i];
                
            // 冒泡排序算法
            for(i=0; i<BLK-1; i=i+1) begin
                for(j=0; j<BLK-1-i; j=j+1) begin
                    if(sort_array[j] > sort_array[j+1]) begin
                        temp = sort_array[j];
                        sort_array[j] = sort_array[j+1];
                        sort_array[j+1] = temp;
                    end
                end
            end
            
            // 将排序结果输出
            for(i=0; i<BLK; i=i+1)
                sorted[i] = sort_array[i];
        end
    end
endmodule

// 数据组装子模块 - 负责重新组装排序后的数据
module Data_Assembler #(parameter BLK=8) (
    input clk, en,
    input [7:0] sorted [0:BLK-1],
    output reg [BLK*8-1:0] data_out
);
    integer i;
    
    always @(posedge clk) begin
        if(en) begin
            // 组装BWT转换后的输出数据
            data_out[7:0] = sorted[BLK-1];
            for(i=1; i<BLK; i=i+1)
                data_out[i*8 +: 8] = sorted[i-1];
        end
    end
endmodule