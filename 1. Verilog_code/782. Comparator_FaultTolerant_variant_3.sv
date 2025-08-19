//SystemVerilog
module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0    // 0:偶校验 1:奇校验
)(
    input  [WIDTH:0]   data_a,   // [WIDTH]为校验位
    input  [WIDTH:0]   data_b,
    output             safe_equal
);
    // 校验位计算
    wire parity_a = ^data_a[WIDTH-1:0];
    wire parity_b = ^data_b[WIDTH-1:0];
    
    // 使用显式多路复用器结构替代三元运算符
    reg expected_parity_a, expected_parity_b;
    
    always @(*) begin
        case(PARITY_TYPE)
            1'b1: begin // 奇校验
                expected_parity_a = ~data_a[WIDTH];
                expected_parity_b = ~data_b[WIDTH];
            end
            1'b0: begin // 偶校验
                expected_parity_a = data_a[WIDTH];
                expected_parity_b = data_b[WIDTH];
            end
        endcase
    end
    
    // 校验结果
    wire parity_ok_a = (parity_a == expected_parity_a);
    wire parity_ok_b = (parity_b == expected_parity_b);
    
    // 数据比较 - 使用按位比较以提高效率
    wire [WIDTH-1:0] compare_vector = data_a[WIDTH-1:0] ~^ data_b[WIDTH-1:0];
    wire data_equal = &compare_vector;
    
    // 安全相等条件
    assign safe_equal = parity_ok_a & parity_ok_b & data_equal;
endmodule