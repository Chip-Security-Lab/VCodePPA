//SystemVerilog
module subtract_xnor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] difference,
    output [7:0] xnor_result
);
    wire [7:0] borrow;
    
    // 优化借位减法器实现
    assign borrow[0] = ~a[0] & b[0];
    assign difference[0] = a[0] ^ b[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin: gen_borrow
            // 简化借位逻辑：使用布尔代数规则重写
            assign borrow[i] = (~a[i] & b[i]) | ((a[i] ~^ b[i]) & borrow[i-1]);
            assign difference[i] = a[i] ^ b[i] ^ borrow[i-1];
        end
    endgenerate
    
    // 异或非操作使用同或运算符直接表示
    assign xnor_result = a ~^ b;
endmodule