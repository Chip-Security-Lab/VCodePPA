//SystemVerilog
module vector_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output [$clog2(WIDTH)-1:0] encoded_position,
    output valid_output
);
    wire [WIDTH-1:0] masked_data;
    
    // 使用显式多路复用器结构实现数据掩码操作
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : mask_gen
            // 使用多路复用器结构代替三元运算符
            wire select;
            assign select = priority_mask[i];
            assign masked_data[i] = select ? data_vector[i] : 1'b0;
        end
    endgenerate
    
    // 优化的优先级编码器实现 - 使用并行处理
    reg [$clog2(WIDTH)-1:0] position;
    reg valid;
    
    // 使用多级多路复用器结构实现优先级编码
    always @(*) begin
        position = {$clog2(WIDTH){1'b0}};
        valid = 1'b0;
        
        // 从高位到低位扫描，确保高优先级位被优先选择
        for (integer j = WIDTH-1; j >= 0; j = j - 1) begin
            if (masked_data[j]) begin
                position = j[$clog2(WIDTH)-1:0];
                valid = 1'b1;
            end
        end
    end
    
    // 显式多路复用器结构实现最终输出
    wire [$clog2(WIDTH)-1:0] default_position;
    wire default_valid;
    
    assign default_position = {$clog2(WIDTH){1'b0}};
    assign default_valid = 1'b0;
    
    // 条件输出赋值
    assign encoded_position = (|masked_data) ? position : default_position;
    assign valid_output = (|masked_data) ? valid : default_valid;
endmodule