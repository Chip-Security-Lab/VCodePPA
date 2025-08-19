//SystemVerilog
module vector_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    input [WIDTH-1:0] priority_mask,
    output reg [$clog2(WIDTH)-1:0] encoded_position,
    output valid_output
);
    wire [WIDTH-1:0] masked_data;
    wire [WIDTH-1:0] borrow_chain;
    wire [WIDTH-1:0] position_bits;
    
    assign masked_data = data_vector & priority_mask;
    assign valid_output = |masked_data;
    
    // 先行借位减法器实现
    assign borrow_chain[0] = 1'b0;
    generate
        for (genvar i = 0; i < WIDTH-1; i++) begin
            assign borrow_chain[i+1] = ~masked_data[i] & borrow_chain[i];
        end
    endgenerate
    
    // 位置编码生成
    generate
        for (genvar i = 0; i < WIDTH; i++) begin
            assign position_bits[i] = masked_data[i] & ~borrow_chain[i];
        end
    endgenerate
    
    // 位置编码转换
    always @(*) begin
        encoded_position = {$clog2(WIDTH){1'b0}};
        for (int i = 0; i < WIDTH; i++) begin
            if (position_bits[i])
                encoded_position = i[$clog2(WIDTH)-1:0];
        end
    end
endmodule