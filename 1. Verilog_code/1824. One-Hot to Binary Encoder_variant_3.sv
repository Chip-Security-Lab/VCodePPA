//SystemVerilog
module onehot_to_binary_priority #(parameter OH_WIDTH = 8) (
    input  wire [OH_WIDTH-1:0] onehot_input,
    output wire [$clog2(OH_WIDTH)-1:0] binary_output,
    output wire valid
);
    // 声明常量
    localparam BIN_WIDTH = $clog2(OH_WIDTH);
    
    // 有效标志信号
    assign valid = |onehot_input;
    
    // 优化的编码方法 - 使用优先级编码器实现
    reg [BIN_WIDTH-1:0] binary_result;
    
    // 使用优先级编码器实现
    integer j;
    always @(*) begin
        binary_result = {BIN_WIDTH{1'b0}};
        for (j = OH_WIDTH-1; j >= 0; j = j - 1) begin
            if (onehot_input[j]) begin
                binary_result = j[BIN_WIDTH-1:0];
            end
        end
    end
    
    // 连接输出
    assign binary_output = binary_result;
    
endmodule