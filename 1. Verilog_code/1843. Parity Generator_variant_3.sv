//SystemVerilog
module parity_generator #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_i,
    input  wire             odd_parity,
    output wire             parity_bit
);
    // 使用树形结构计算奇偶校验，减少关键路径延迟
    wire [WIDTH/2-1:0] stage1;
    wire [WIDTH/4-1:0] stage2;
    wire [WIDTH/8-1:0] stage3;
    
    // 第一级异或
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin
            assign stage1[i] = data_i[2*i] ^ data_i[2*i+1];
        end
    endgenerate
    
    // 第二级异或
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin
            assign stage2[i] = stage1[2*i] ^ stage1[2*i+1];
        end
    endgenerate
    
    // 第三级异或
    generate
        for (i = 0; i < WIDTH/8; i = i + 1) begin
            assign stage3[i] = stage2[2*i] ^ stage2[2*i+1];
        end
    endgenerate
    
    // 最终输出
    assign parity_bit = ^stage3 ^ odd_parity;
endmodule