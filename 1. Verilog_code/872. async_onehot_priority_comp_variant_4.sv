//SystemVerilog
module async_onehot_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] priority_onehot,
    output valid
);

    // 使用前缀树结构优化掩码生成
    wire [WIDTH-1:0] mask;
    wire [WIDTH-1:0] prefix_or;
    
    // 生成前缀或
    assign prefix_or[0] = data_in[0];
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign prefix_or[i] = prefix_or[i-1] | data_in[i];
        end
    endgenerate
    
    // 生成掩码
    assign mask[0] = 1'b1;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin
            assign mask[i] = ~prefix_or[i-1];
        end
    endgenerate
    
    // 生成优先级单热码输出
    assign priority_onehot = data_in & mask;
    
    // 检测有效位
    assign valid = prefix_or[WIDTH-1];

endmodule