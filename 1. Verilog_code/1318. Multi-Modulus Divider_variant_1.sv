//SystemVerilog
//=============================================================================
// Filename: multimod_divider.v
// 顶层模块：可配置时钟分频器
//=============================================================================
module multimod_divider (
    input  wire       CLK_IN,   // 输入时钟
    input  wire       RST,      // 异步复位信号
    input  wire       ENABLE,   // 使能信号
    input  wire [2:0] DIV_SEL,  // 分频选择
    output wire       CLK_OUT   // 输出时钟
);

    // 内部连线
    wire [3:0] div_value;

    // 分频值解码器实例
    div_decoder div_decoder_inst (
        .DIV_SEL   (DIV_SEL),
        .div_value (div_value)
    );

    // 时钟分频器实例
    clock_divider clock_divider_inst (
        .CLK_IN    (CLK_IN),
        .RST       (RST),
        .ENABLE    (ENABLE),
        .div_value (div_value),
        .CLK_OUT   (CLK_OUT)
    );

endmodule

//=============================================================================
// 子模块：分频值解码器
// 根据选择信号生成对应的分频值
//=============================================================================
module div_decoder (
    input  wire [2:0] DIV_SEL,    // 分频选择输入
    output reg  [3:0] div_value   // 解码后的分频值
);

    // 参数定义
    localparam DIV_1  = 4'd1;
    localparam DIV_2  = 4'd2;
    localparam DIV_4  = 4'd4;
    localparam DIV_8  = 4'd8;
    localparam DIV_16 = 4'd16;

    // 解码逻辑
    always @(*) begin
        case (DIV_SEL)
            3'd0:    div_value = DIV_1;
            3'd1:    div_value = DIV_2;
            3'd2:    div_value = DIV_4;
            3'd3:    div_value = DIV_8;
            default: div_value = DIV_16;
        endcase
    end

endmodule

//=============================================================================
// 子模块：时钟分频器
// 使用Booth乘法器算法实现计算
//=============================================================================
module clock_divider (
    input  wire       CLK_IN,    // 输入时钟
    input  wire       RST,       // 异步复位信号
    input  wire       ENABLE,    // 使能信号
    input  wire [3:0] div_value, // 分频值
    output reg        CLK_OUT    // 输出时钟
);

    // 内部寄存器和信号
    reg [3:0] counter;
    reg [3:0] booth_multiplier;
    reg [3:0] booth_multiplicand;
    reg [7:0] booth_product;
    reg [4:0] booth_temp;
    reg [2:0] booth_state;
    reg       booth_done;
    
    // Booth乘法运算状态
    localparam IDLE = 3'd0;
    localparam INIT = 3'd1;
    localparam CALC = 3'd2;
    localparam DONE = 3'd3;
    
    // Booth乘法器实现
    always @(posedge CLK_IN or posedge RST) begin
        if (RST) begin
            counter <= 4'd0;
            CLK_OUT <= 1'b0;
            booth_state <= IDLE;
            booth_done <= 1'b0;
            booth_multiplier <= 4'd0;
            booth_multiplicand <= 4'd0;
            booth_product <= 8'd0;
            booth_temp <= 5'd0;
        end else if (ENABLE) begin
            case (booth_state)
                IDLE: begin
                    // 准备进行乘法运算
                    booth_multiplier <= counter;
                    booth_multiplicand <= div_value;
                    booth_state <= INIT;
                end
                
                INIT: begin
                    // 初始化Booth乘法
                    booth_product <= {4'd0, booth_multiplier, 1'b0};
                    booth_temp <= 5'd2; // 控制迭代次数
                    booth_state <= CALC;
                end
                
                CALC: begin
                    // Booth算法核心逻辑
                    if (booth_temp > 5'd0) begin
                        case (booth_product[1:0])
                            2'b01: booth_product[7:4] = booth_product[7:4] + booth_multiplicand;
                            2'b10: booth_product[7:4] = booth_product[7:4] - booth_multiplicand;
                            default: ; // 00或11时不需要操作
                        endcase
                        
                        // 算术右移
                        booth_product <= {booth_product[7], booth_product[7:1]};
                        booth_temp <= booth_temp - 5'd1;
                    end else begin
                        booth_state <= DONE;
                    end
                end
                
                DONE: begin
                    booth_done <= 1'b1;
                    booth_state <= IDLE;
                    
                    // 使用计算结果进行时钟分频
                    if (booth_product[3:0] >= div_value - 1'b1) begin
                        counter <= 4'd0;
                        CLK_OUT <= ~CLK_OUT;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                
                default: booth_state <= IDLE;
            endcase
        end
    end

endmodule