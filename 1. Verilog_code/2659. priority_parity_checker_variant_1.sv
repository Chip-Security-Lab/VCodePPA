//SystemVerilog
module priority_parity_checker (
    input [15:0] data,
    output reg [3:0] parity,
    output reg error
);
    wire [7:0] low_byte;
    wire [7:0] high_byte;
    wire byte_parity;
    wire [7:0] low_byte_parity;
    wire [7:0] high_byte_parity;
    wire [3:0] priority_encoded;
    wire low_byte_nonzero;
    
    // 拆分数据为高低字节
    assign low_byte = data[7:0];
    assign high_byte = data[15:8];
    
    // 计算整体奇偶校验
    assign byte_parity = ^low_byte ^ ^high_byte;
    
    // 检测低字节是否非零
    assign low_byte_nonzero = |low_byte;
    
    // 并行计算低字节和高字节的奇偶校验
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : parity_gen
            assign low_byte_parity[i] = ^low_byte[i:0];
            assign high_byte_parity[i] = ^high_byte[i:0];
        end
    endgenerate
    
    // 显式多路复用器实现优先级编码
    wire sel7, sel6, sel5, sel4, sel3, sel2, sel1, sel0;
    assign sel7 = low_byte[7];
    assign sel6 = ~sel7 & low_byte[6];
    assign sel5 = ~sel7 & ~sel6 & low_byte[5];
    assign sel4 = ~sel7 & ~sel6 & ~sel5 & low_byte[4];
    assign sel3 = ~sel7 & ~sel6 & ~sel5 & ~sel4 & low_byte[3];
    assign sel2 = ~sel7 & ~sel6 & ~sel5 & ~sel4 & ~sel3 & low_byte[2];
    assign sel1 = ~sel7 & ~sel6 & ~sel5 & ~sel4 & ~sel3 & ~sel2 & low_byte[1];
    assign sel0 = ~sel7 & ~sel6 & ~sel5 & ~sel4 & ~sel3 & ~sel2 & ~sel1 & low_byte[0];
    
    // 多路复用器输出
    assign priority_encoded[3] = sel7;
    assign priority_encoded[2] = sel6 | sel7 | sel5 | sel4;
    assign priority_encoded[1] = sel6 | sel7 | sel3 | sel2;
    assign priority_encoded[0] = sel7 | sel5 | sel3 | sel1;
    
    // 输出逻辑使用多路复用器结构
    always @(*) begin
        // 默认值
        parity = 4'h0;
        error = 1'b0;
        
        // 多路复用器结构
        if (byte_parity & low_byte_nonzero) begin
            parity = priority_encoded;
            error = 1'b1;
        end else begin
            parity = 4'h0;
            error = 1'b0;
        end
    end
endmodule