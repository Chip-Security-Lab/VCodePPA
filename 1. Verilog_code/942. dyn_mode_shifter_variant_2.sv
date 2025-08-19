//SystemVerilog
module dyn_mode_shifter (
    input [15:0] data,
    input [3:0] shift,
    input [1:0] mode, // 00-逻辑左 01-算术右 10-循环 11-Karatsuba乘法
    input [15:0] mult_operand, // 用于乘法的第二个操作数
    output reg [15:0] res
);

wire [15:0] karatsuba_result;

// 实例化Karatsuba乘法器
karatsuba_multiplier #(
    .WIDTH(16)
) kmult (
    .a(data),
    .b(mult_operand),
    .y(karatsuba_result)
);

always @* begin
    case(mode)
        2'b00: res = data << shift;
        2'b01: res = $signed(data) >>> shift;
        2'b10: res = (data << shift) | (data >> (16 - shift));
        2'b11: res = karatsuba_result; // Karatsuba乘法结果
        default: res = data;
    endcase
end
endmodule

// 递归Karatsuba乘法器模块
module karatsuba_multiplier #(
    parameter WIDTH = 16
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);

generate
    if (WIDTH <= 4) begin : BASE_CASE
        // 基本情况：直接乘法
        assign y = a * b;
    end else begin : RECURSIVE_CASE
        // 递归Karatsuba算法实现
        localparam HALF_WIDTH = WIDTH / 2;
        
        wire [HALF_WIDTH-1:0] a_low, b_low;
        wire [HALF_WIDTH-1:0] a_high, b_high;
        
        assign a_low = a[HALF_WIDTH-1:0];
        assign a_high = a[WIDTH-1:HALF_WIDTH];
        assign b_low = b[HALF_WIDTH-1:0];
        assign b_high = b[WIDTH-1:HALF_WIDTH];
        
        wire [HALF_WIDTH-1:0] z0, z1, z2;
        
        // 递归计算三个子乘积
        karatsuba_multiplier #(
            .WIDTH(HALF_WIDTH)
        ) z0_mult (
            .a(a_low),
            .b(b_low),
            .y(z0)  // z0 = a_low * b_low
        );
        
        karatsuba_multiplier #(
            .WIDTH(HALF_WIDTH)
        ) z2_mult (
            .a(a_high),
            .b(b_high),
            .y(z2)  // z2 = a_high * b_high
        );
        
        wire [HALF_WIDTH-1:0] a_sum, b_sum;
        assign a_sum = a_low + a_high;
        assign b_sum = b_low + b_high;
        
        karatsuba_multiplier #(
            .WIDTH(HALF_WIDTH)
        ) z1_mult (
            .a(a_sum),
            .b(b_sum),
            .y(z1)  // z1 = (a_low + a_high) * (b_low + b_high)
        );
        
        wire [HALF_WIDTH-1:0] mid_term;
        assign mid_term = z1 - z2 - z0;
        
        // 最终结果组合
        assign y = {z2, {HALF_WIDTH{1'b0}}} + {{HALF_WIDTH/2{1'b0}}, mid_term, {HALF_WIDTH/2{1'b0}}} + z0;
    end
endgenerate

endmodule