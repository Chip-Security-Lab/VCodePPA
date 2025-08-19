//SystemVerilog
module vector_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output reg [$clog2(WIDTH)-1:0] encoded_position,
    output valid_output
);
    wire [WIDTH-1:0] masked_data;
    assign masked_data = data_vector & priority_mask;
    assign valid_output = |masked_data;
    
    // 优化的优先级编码器逻辑
    always @(*) begin
        encoded_position = {$clog2(WIDTH){1'b0}};
        
        // 使用casex替代for循环提高效率
        casex(masked_data)
            // 从高位到低位检查，第一个匹配的将被执行
            {1'b1, {(WIDTH-1){1'bx}}}: encoded_position = WIDTH-1;
            {{1'b0}, {1'b1}, {(WIDTH-2){1'bx}}}: encoded_position = WIDTH-2;
            {{2'b0}, {1'b1}, {(WIDTH-3){1'bx}}}: encoded_position = WIDTH-3;
            {{3'b0}, {1'b1}, {(WIDTH-4){1'bx}}}: encoded_position = WIDTH-4;
            {{4'b0}, {1'b1}, {(WIDTH-5){1'bx}}}: encoded_position = WIDTH-5;
            {{5'b0}, {1'b1}, {(WIDTH-6){1'bx}}}: encoded_position = WIDTH-6;
            {{6'b0}, {1'b1}, {(WIDTH-7){1'bx}}}: encoded_position = WIDTH-7;
            {{7'b0}, {1'b1}}: encoded_position = 0;
            default: encoded_position = {$clog2(WIDTH){1'b0}};
        endcase
    end
endmodule