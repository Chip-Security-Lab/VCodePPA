//SystemVerilog
module not_gate_param #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] A,
    output wire [WIDTH-1:0] Y
);
    // 使用借位减法器算法实现反相器
    wire [WIDTH-1:0] borrow;
    wire [WIDTH-1:0] temp_result;
    
    // 初始化最低位借位
    assign borrow[0] = 1'b1;
    
    // 生成借位减法器逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            if (i < WIDTH-1) begin
                assign borrow[i+1] = ~A[i] & borrow[i];
            end
            assign temp_result[i] = A[i] ^ borrow[i];
        end
    endgenerate
    
    // 输出结果
    assign Y = temp_result;
endmodule