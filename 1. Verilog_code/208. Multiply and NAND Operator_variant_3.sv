//SystemVerilog
// 顶层模块
module multiply_nand_operator (
    input [15:0] a,
    input [15:0] b,
    output [31:0] product,
    output [15:0] nand_result
);
    // 实例化乘法器子模块
    multiplier mult_inst (
        .operand_a(a),
        .operand_b(b),
        .product(product)
    );
    
    // 实例化与非运算子模块
    nand_operator nand_inst (
        .operand_a(a),
        .operand_b(b),
        .result(nand_result)
    );
endmodule

// 乘法器子模块 - 使用Booth算法实现
module multiplier #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH*2-1:0] product
);
    // Booth乘法器实现
    reg [WIDTH*2-1:0] product_reg;
    reg [WIDTH:0] A, S;
    reg [WIDTH*2:0] P;
    integer i;
    
    always @(*) begin
        // 初始化A, S和P
        A = {operand_a, 1'b0};
        S = {(~operand_a + 1'b1), 1'b0};
        P = {16'b0, operand_b, 1'b0};
        
        // Booth算法迭代
        for (i = 0; i < WIDTH; i = i + 1) begin
            case (P[1:0])
                2'b01: P[WIDTH*2:WIDTH] = P[WIDTH*2:WIDTH] + A;
                2'b10: P[WIDTH*2:WIDTH] = P[WIDTH*2:WIDTH] + S;
                default: ; // 对于00和11不做操作
            endcase
            
            // 算术右移
            P = {P[WIDTH*2], P[WIDTH*2:1]};
        end
        
        // 最终结果
        product_reg = P[WIDTH*2:1];
    end
    
    assign product = product_reg;
endmodule

// 与非运算子模块
module nand_operator #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    // 位级与非操作
    genvar i;
    wire [WIDTH-1:0] and_result;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : nand_bit
            assign and_result[i] = operand_a[i] & operand_b[i];
        end
    endgenerate
    
    assign result = ~and_result;
endmodule