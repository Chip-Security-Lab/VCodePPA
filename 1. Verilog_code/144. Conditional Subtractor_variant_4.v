module shift_add_multiplier (
    input wire [7:0] a,      // Multiplicand
    input wire [7:0] b,      // Multiplier
    output reg [15:0] result // Product
);

reg [7:0] multiplicand;
reg [7:0] multiplier;
reg [15:0] product;
integer i;

always @(*) begin
    multiplicand = a;
    multiplier = b;
    product = 16'b0;
    
    for (i = 0; i < 8; i = i + 1) begin
        if (multiplier[0] == 1'b1) begin
            product = product + {8'b0, multiplicand};
        end
        multiplicand = multiplicand << 1;
        multiplier = multiplier >> 1;
    end
    
    result = product;
end

endmodule

module subtractor_conditional (
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

wire [15:0] mult_result;
wire [7:0] scaled_b;
wire [7:0] diff;
wire sel;

// 使用移位累加乘法器计算 b * 1
shift_add_multiplier mult_unit (
    .a(8'b1),
    .b(b),
    .result(mult_result)
);

// 取乘法结果的低8位
assign scaled_b = mult_result[7:0];

// 计算差值
assign diff = a - scaled_b;

// 生成选择信号
assign sel = (a >= scaled_b);

// 使用显式多路复用器结构
always @(*) begin
    res = sel ? diff : 8'b0;
end

endmodule