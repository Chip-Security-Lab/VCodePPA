//SystemVerilog
module AsyncRst_NAND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [3:0] q
);
    wire [7:0] mult_result;
    wire [3:0] reset_value;
    
    // 实例化Karatsuba乘法器
    karatsuba_multiplier_4bit kmult (
        .a(src1),
        .b(src2),
        .product(mult_result)
    );
    
    // 定义复位值
    assign reset_value = 4'b1111;
    
    // 使用乘法结果的低4位作为输出
    always @(*) begin
        if (rst_n == 1'b1) begin
            q = mult_result[3:0];
        end
        else if (rst_n == 1'b0) begin
            q = reset_value;
        end
        else begin
            q = reset_value; // 确保处理所有情况
        end
    end
endmodule

// Karatsuba乘法器顶层模块(4位)
module karatsuba_multiplier_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [7:0] term1, term2, term3;
    
    // 由于是4位输入，我们将其分为2位高位和2位低位
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // 递归计算三个子乘积
    karatsuba_multiplier_2bit kmult1 (
        .a(a_high),
        .b(b_high),
        .product(p1)
    );
    
    karatsuba_multiplier_2bit kmult2 (
        .a(a_low),
        .b(b_low),
        .product(p2)
    );
    
    karatsuba_multiplier_2bit kmult3 (
        .a(a_high ^ a_low),  // 异或操作替代加法，减少进位逻辑
        .b(b_high ^ b_low),
        .product(p3)
    );
    
    // 计算最终结果
    assign term1 = {p1, 4'b0000};
    assign term2 = {{2{1'b0}}, p2};
    assign term3 = {{1{1'b0}}, (p3 ^ p1 ^ p2), {1{1'b0}}};
    
    assign product = term1 ^ term2 ^ term3;
endmodule

// 2位Karatsuba乘法器子模块
module karatsuba_multiplier_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] product
);
    wire p0, p1, p2, p3;
    
    // 基本乘法运算 (2位乘法可以直接展开)
    assign p0 = a[0] & b[0];
    assign p1 = a[0] & b[1];
    assign p2 = a[1] & b[0];
    assign p3 = a[1] & b[1];
    
    // 组合计算结果
    assign product[0] = p0;
    assign product[1] = p1 ^ p2;
    assign product[2] = p3 ^ (p1 & p2);
    assign product[3] = p3 & (p1 | p2);
endmodule