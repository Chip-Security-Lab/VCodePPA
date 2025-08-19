//SystemVerilog
module BWT_Compress #(BLK=8) (
    input clk, en,
    input [BLK*8-1:0] data_in,
    output reg [BLK*8-1:0] data_out
);
    reg [7:0] buffer [0:BLK-1];
    reg [7:0] sorted [0:BLK-1];
    integer i, j;
    reg [7:0] temp;
    reg [7:0] index_val, next_index_val;
    wire [7:0] cla_result;
    
    // 带状进位加法器子模块的实例化
    CLA_Adder cla_inst (
        .a(index_val),
        .b(8'h01),
        .cin(1'b0),
        .sum(cla_result)
    );

    always @(posedge clk) begin
        if(en) begin
            // 提取数据到buffer
            for(i=0; i<BLK; i=i+1)
                buffer[i] = data_in[i*8 +: 8];
                
            // 复制到排序数组
            for(i=0; i<BLK; i=i+1)
                sorted[i] = buffer[i];
                
            // 实现简单的冒泡排序，使用带状进位加法器进行索引递增
            for(i=0; i<BLK-1; i=i+1) begin
                index_val = 0;
                for(j=0; j<BLK-1-i; j=j+1) begin
                    // 使用带状进位加法器计算下一个索引值
                    index_val = j;
                    next_index_val = cla_result;
                    
                    if(sorted[j] > sorted[next_index_val]) begin
                        temp = sorted[j];
                        sorted[j] = sorted[next_index_val];
                        sorted[next_index_val] = temp;
                    end
                end
            end
            
            // 组装输出数据
            data_out[7:0] = sorted[BLK-1];
            for(i=1; i<BLK; i=i+1)
                data_out[i*8 +: 8] = sorted[i-1];
        end
    end
endmodule

// 8位带状进位加法器 - 优化后的实现
module CLA_Adder (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum
);
    wire [7:0] p, g;
    wire [8:0] c;
    
    // 生成传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 设置初始进位
    assign c[0] = cin;
    
    // 优化后的进位计算 - 采用更简洁的布尔表达式
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c[3] = g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & cin)))));
    assign c[4] = g[3] | (p[3] & (g[2] | (p[2] & (g[1] | (p[1] & (g[0] | (p[0] & cin)))))));
    
    // 第二级进位计算（分组）- 使用因式分解简化表达式
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & (g[4] | (p[4] & c[4])));
    assign c[7] = g[6] | (p[6] & (g[5] | (p[5] & (g[4] | (p[4] & c[4])))));
    assign c[8] = g[7] | (p[7] & (g[6] | (p[6] & (g[5] | (p[5] & (g[4] | (p[4] & c[4])))))));
    
    // 计算求和
    assign sum = p ^ c[7:0];
endmodule