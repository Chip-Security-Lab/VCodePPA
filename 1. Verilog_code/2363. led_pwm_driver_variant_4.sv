//SystemVerilog
module led_pwm_driver #(parameter W=8)(
    input clk, 
    input [W-1:0] duty,
    output reg pwm_out
);
    // 寄存器定义
    reg [W-1:0] cnt_reg;
    
    // 组合逻辑信号
    wire [W-1:0] cnt_next;
    wire pwm_next;
    wire [W-1:0] subtraction_result;
    wire borrow_out;
    
    // 组合逻辑部分 - 计数器增量
    assign cnt_next = cnt_reg + 1'b1;
    
    // 组合逻辑模块实例化 - 减法器
    lut_subtractor_comb #(.WIDTH(W)) sub_unit (
        .minuend(duty),
        .subtrahend(cnt_reg),
        .difference(subtraction_result),
        .borrow_out(borrow_out)
    );
    
    // 组合逻辑部分 - PWM输出计算
    assign pwm_next = ~borrow_out; // PWM高电平条件: duty > cnt_reg
    
    // 时序逻辑部分
    always @(posedge clk) begin
        cnt_reg <= cnt_next;
        pwm_out <= pwm_next;
    end
endmodule

// 纯组合逻辑减法器模块
module lut_subtractor_comb #(parameter WIDTH=8)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output borrow_out
);
    // 内部信号声明
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff_bit;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 使用generate生成位级减法逻辑
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sub_bit
            // 每一位的差值计算: diff = a ^ b ^ borrow_in
            assign diff_bit[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            
            // 借位逻辑: borrow_out = (~a & b) | (borrow_in & (~a | b))
            assign borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                                 (borrow[i] & (~minuend[i] | subtrahend[i]));
        end
    endgenerate
    
    // 输出连接
    assign difference = diff_bit;
    assign borrow_out = borrow[WIDTH];
endmodule