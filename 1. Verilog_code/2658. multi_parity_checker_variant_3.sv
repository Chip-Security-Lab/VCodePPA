//SystemVerilog
module multi_parity_checker (
    input [1:0] mode, // 00: no, 01: even, 10: odd, 11: invert
    input [7:0] data,
    input [7:0] multiplier,  // 新增乘法器输入
    output reg [1:0] parity,
    output reg [15:0] product  // 乘法结果输出
);
    wire even_p = ~^data;
    wire odd_p = ^data;
    
    // 乘法相关信号定义
    reg [15:0] partial_product;
    reg [15:0] shift_product;
    reg [7:0] shift_multiplier;
    reg [7:0] multiplicand;
    
    // 计算乘法的部分积
    always @(*) begin
        partial_product = shift_multiplier[0] ? {8'd0, multiplicand} : 16'd0;
    end
    
    // 初始化乘法器状态
    always @(*) begin
        shift_multiplier = multiplier;
        multiplicand = data;
        shift_product = 16'd0;
    end
    
    // 乘法迭代计算
    integer i;
    always @(*) begin
        shift_product = 16'd0;
        shift_multiplier = multiplier;
        multiplicand = data;
        
        for (i = 0; i < 8; i = i + 1) begin
            if (shift_multiplier[0])
                shift_product = shift_product + {8'd0, multiplicand};
            
            shift_multiplier = shift_multiplier >> 1;
            multiplicand = multiplicand << 1;
        end
    end
    
    // 输出乘法结果
    always @(*) begin
        product = shift_product;
    end

    // 奇偶校验计算
    always @(*) begin
        case(mode)
            2'b00: parity = 2'b00;
            2'b01: parity = {even_p, 1'b0};
            2'b10: parity = {odd_p, 1'b1};
            2'b11: parity = {~odd_p, 1'b1};
        endcase
    end
endmodule