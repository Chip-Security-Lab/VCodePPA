//SystemVerilog
module error_detect_decoder(
    input [1:0] addr,
    input valid,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] select,
    output reg error,
    output [7:0] product
);
    // 分解为独立的always块处理select信号
    always @(*) begin
        select = 4'b0000;
        if (valid) begin
            select[addr] = 1'b1;
        end
    end
    
    // 独立的always块处理error信号
    always @(*) begin
        error = 1'b0;
        if (!valid) begin
            error = 1'b1;
        end
    end
    
    // 集成递归Karatsuba乘法器
    karatsuba_multiplier_4bit kmult (
        .a(a),
        .b(b),
        .product(product)
    );
endmodule

module karatsuba_multiplier_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [3:0] term1, term2, term3;
    wire [3:0] a_sum, b_sum;
    
    // 拆分操作数
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // 计算加和项
    assign a_sum = {2'b00, a_high} + {2'b00, a_low};
    assign b_sum = {2'b00, b_high} + {2'b00, b_low};
    
    // 计算三个部分积
    karatsuba_multiplier_2bit km1 (
        .a(a_high),
        .b(b_high),
        .product(p1)
    );
    
    karatsuba_multiplier_2bit km2 (
        .a(a_low),
        .b(b_low),
        .product(p2)
    );
    
    karatsuba_multiplier_2bit km3 (
        .a(a_sum[1:0]),
        .b(b_sum[1:0]),
        .product(p3)
    );
    
    // 计算中间项
    assign term3 = p3 - p1 - p2;
    
    // 组合最终结果
    assign product = {p1, 4'b0000} + {2'b00, term3, 2'b00} + {4'b0000, p2};
endmodule

module karatsuba_multiplier_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] product
);
    wire a1, a0, b1, b0;
    wire p1, p2;
    wire p3_and;
    wire [1:0] p3;
    wire [1:0] term3;
    
    // 拆分操作数
    assign a1 = a[1];
    assign a0 = a[0];
    assign b1 = b[1];
    assign b0 = b[0];
    
    // 基本乘法项
    assign p1 = a1 & b1;
    assign p2 = a0 & b0;
    assign p3_and = (a1 | a0) & (b1 | b0);
    assign p3 = {1'b0, p3_and};
    
    // 计算中间项
    assign term3 = p3 - {1'b0, p1} - {1'b0, p2};
    
    // 组合最终结果
    assign product = {p1, 2'b00} + {1'b0, term3, 1'b0} + {2'b00, p2};
endmodule