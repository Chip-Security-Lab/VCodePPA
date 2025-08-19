//SystemVerilog

// 顶层模块
module dual_output_decoder(
    input [2:0] binary_in,
    output [7:0] onehot_out,
    output [2:0] gray_out,
    // 新增乘法器接口
    input [7:0] multiplicand,
    input [7:0] multiplier,
    input clk,
    input reset,
    input start,
    output reg [15:0] product,
    output reg done
);
    // 实例化one-hot转换子模块
    binary_to_onehot_converter onehot_converter (
        .binary_in(binary_in),
        .onehot_out(onehot_out)
    );
    
    // 实例化格雷码转换子模块
    binary_to_gray_converter gray_converter (
        .binary_in(binary_in),
        .gray_out(gray_out)
    );
    
    // 实例化Booth乘法器
    booth_multiplier_8bit booth_mult (
        .clk(clk),
        .reset(reset),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product),
        .done(done)
    );
endmodule

// One-hot编码转换子模块
module binary_to_onehot_converter(
    input [2:0] binary_in,
    output reg [7:0] onehot_out
);
    always @(*) begin
        onehot_out = (8'b1 << binary_in);
    end
endmodule

// 格雷码转换子模块
module binary_to_gray_converter(
    input [2:0] binary_in,
    output reg [2:0] gray_out
);
    always @(*) begin
        gray_out[2] = binary_in[2];
        gray_out[1] = binary_in[2] ^ binary_in[1];
        gray_out[0] = binary_in[1] ^ binary_in[0];
    end
endmodule

// Booth乘法器模块 (8位)
module booth_multiplier_8bit(
    input clk,
    input reset,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] counter;
    reg [16:0] partial_product; // 额外1位用于Booth算法
    reg [7:0] booth_multiplicand;
    reg [8:0] booth_multiplier;  // 额外1位用于Booth算法
    
    // 状态机
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            counter <= 0;
            partial_product <= 0;
            booth_multiplicand <= 0;
            booth_multiplier <= 0;
            product <= 0;
            done <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start) begin
                        booth_multiplicand <= multiplicand;
                        booth_multiplier <= {multiplier, 1'b0}; // 添加额外位
                        partial_product <= 0;
                        counter <= 0;
                        done <= 0;
                    end
                end
                
                CALC: begin
                    if (counter < 8) begin
                        case (booth_multiplier[1:0])
                            2'b01: partial_product <= partial_product + {booth_multiplicand, 8'b0};
                            2'b10: partial_product <= partial_product - {booth_multiplicand, 8'b0};
                            default: partial_product <= partial_product; // 00 或 11 不做操作
                        endcase
                        
                        // 算术右移
                        booth_multiplier <= {booth_multiplier[8], booth_multiplier[8:1]};
                        counter <= counter + 1;
                    end
                end
                
                DONE: begin
                    product <= partial_product[16:1]; // 移除额外位
                    done <= 1;
                end
            endcase
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (counter == 8) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule