//SystemVerilog
module configurable_clock_gate (
    input  wire clk_in,
    input  wire [1:0] mode,
    input  wire ctrl,
    output wire clk_out
);
    reg gate_signal;
    wire [1:0] booth_multiplier;
    wire [1:0] booth_multiplicand;
    wire [3:0] booth_product;
    
    // 设置乘法器输入
    assign booth_multiplier = mode;
    assign booth_multiplicand = {ctrl, 1'b1};
    
    // 实例化Booth乘法器
    booth_multiplier_2bit booth_mult (
        .multiplier(booth_multiplier),
        .multiplicand(booth_multiplicand),
        .product(booth_product)
    );
    
    // 基于Booth乘法结果决定门控信号
    always @(*) begin
        case (mode)
            2'b00: gate_signal = booth_product[0];     // Direct mode (ctrl)
            2'b01: gate_signal = ~booth_product[0];    // Inverted mode (~ctrl)
            2'b10: gate_signal = 1'b1;                 // Always on
            2'b11: gate_signal = 1'b0;                 // Always off
        endcase
    end
    
    // 最终时钟门控
    assign clk_out = clk_in & gate_signal;
endmodule

module booth_multiplier_2bit (
    input  wire [1:0] multiplier,
    input  wire [1:0] multiplicand,
    output wire [3:0] product
);
    reg [3:0] pp; // 部分积
    reg [2:0] extended_multiplier;
    
    // Booth编码实现
    always @(*) begin
        // 扩展乘数，添加一个0位
        extended_multiplier = {multiplier, 1'b0};
        
        // 初始化部分积
        pp = 4'b0000;
        
        // 2位Booth算法
        // 检查位对[1:0]
        case (extended_multiplier[1:0])
            2'b01: pp = pp + {2'b00, multiplicand};       // +1 * multiplicand
            2'b10: pp = pp - {2'b00, multiplicand};       // -1 * multiplicand
            default: pp = pp;                             // 0 * multiplicand (00 or 11)
        endcase
        
        // 检查位对[2:1]
        pp = pp << 1;
        case (extended_multiplier[2:1])
            2'b01: pp = pp + {1'b0, multiplicand, 1'b0};  // +1 * multiplicand << 1
            2'b10: pp = pp - {1'b0, multiplicand, 1'b0};  // -1 * multiplicand << 1
            default: pp = pp;                             // 0 * multiplicand (00 or 11)
        endcase
    end
    
    // 乘法结果输出
    assign product = pp;
endmodule