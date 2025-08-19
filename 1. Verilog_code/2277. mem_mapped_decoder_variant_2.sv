//SystemVerilog
module mem_mapped_decoder(
    input [7:0] addr,
    input [1:0] bank_sel,
    input [7:0] mult_a,
    input [7:0] mult_b,
    output reg [3:0] chip_sel,
    output [15:0] product
);
    // 使用条件运算符的地址解码逻辑
    always @(*) begin
        chip_sel = 4'b0000;
        chip_sel[bank_sel] = (addr >= 8'h00 && addr <= 8'h7F) ? 1'b1 : 1'b0;
    end
    
    // 递归Karatsuba乘法器实例化
    karatsuba_multiplier #(
        .WIDTH(8)
    ) mult_inst (
        .a(mult_a),
        .b(mult_b),
        .p(product)
    );
endmodule

// 递归Karatsuba乘法器模块
module karatsuba_multiplier #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] p
);
    generate
        if (WIDTH <= 4) begin : small_mult
            // 当位宽小于等于4时，使用普通乘法
            assign p = a * b;
        end
        else begin : karatsuba_impl
            // 分割为高低位
            localparam HALF_WIDTH = WIDTH / 2;
            localparam REM_WIDTH = WIDTH - HALF_WIDTH;
            
            // 将a,b划分为高低位部分
            wire [HALF_WIDTH-1:0] a_lo, b_lo;
            wire [REM_WIDTH-1:0] a_hi, b_hi;
            
            assign a_lo = a[HALF_WIDTH-1:0];
            assign a_hi = a[WIDTH-1:HALF_WIDTH];
            assign b_lo = b[HALF_WIDTH-1:0];
            assign b_hi = b[WIDTH-1:HALF_WIDTH];
            
            // 递归计算三个子乘积
            wire [2*HALF_WIDTH-1:0] p_lo;  // a_lo * b_lo
            wire [2*REM_WIDTH-1:0] p_hi;   // a_hi * b_hi
            wire [HALF_WIDTH+REM_WIDTH-1:0] p_mid; // (a_lo+a_hi)*(b_lo+b_hi) - p_lo - p_hi
            
            wire [REM_WIDTH:0] a_sum;      // a_lo + a_hi
            wire [REM_WIDTH:0] b_sum;      // b_lo + b_hi
            wire [2*REM_WIDTH+1:0] sum_product; // (a_lo+a_hi)*(b_lo+b_hi)
            
            // 计算子乘积
            karatsuba_multiplier #(.WIDTH(HALF_WIDTH)) low_mult (
                .a(a_lo),
                .b(b_lo),
                .p(p_lo)
            );
            
            karatsuba_multiplier #(.WIDTH(REM_WIDTH)) high_mult (
                .a(a_hi),
                .b(b_hi),
                .p(p_hi)
            );
            
            assign a_sum = a_lo + a_hi;
            assign b_sum = b_lo + b_hi;
            
            karatsuba_multiplier #(.WIDTH(REM_WIDTH+1)) mid_mult (
                .a(a_sum),
                .b(b_sum),
                .p(sum_product)
            );
            
            // 计算中间项 (a_lo+a_hi)*(b_lo+b_hi) - p_lo - p_hi
            assign p_mid = sum_product - p_lo - p_hi;
            
            // 组合最终结果 p_hi << WIDTH + p_mid << HALF_WIDTH + p_lo
            assign p = {p_hi, {HALF_WIDTH{1'b0}}} + {{REM_WIDTH{1'b0}}, p_mid, {HALF_WIDTH{1'b0}}} + {{WIDTH{1'b0}}, p_lo};
        end
    endgenerate
endmodule