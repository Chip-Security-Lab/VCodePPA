//SystemVerilog
module decoder_multi_protocol (
    input mode,
    input [15:0] addr,
    output reg [3:0] sel
);
    // 内部信号，用于分别存储两种模式下的解码结果
    reg [3:0] sel_mode0;
    reg [3:0] sel_mode1;
    reg mode0_match, mode1_match;

    // 模式0解码逻辑：检查高4位并设置匹配标志
    always @(*) begin
        mode0_match = (addr[15:12] == 4'ha);
        sel_mode0 = mode0_match ? addr[3:0] : 4'b0000;
    end

    // 模式1解码逻辑：检查中间4位并设置匹配标志
    always @(*) begin
        mode1_match = (addr[7:4] == 4'h5);
        sel_mode1 = mode1_match ? addr[3:0] : 4'b0000;
    end

    // 最终输出选择逻辑：根据模式选择对应的输出
    always @(*) begin
        case(mode)
            1'b0: sel = sel_mode0;
            1'b1: sel = sel_mode1;
            default: sel = 4'b0000;
        endcase
    end
endmodule

module karatsuba_multiplier_16bit (
    input clk,
    input rst_n,
    input start,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] a_reg, b_reg;
    wire [31:0] mult_result;
    
    // 状态机控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            result <= 32'b0;
            done <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        a_reg <= a;
                        b_reg <= b;
                    end
                end
                
                CALC: begin
                    // 无需额外操作，组合逻辑将计算结果
                end
                
                DONE: begin
                    result <= mult_result;
                    done <= 1'b1;
                end
                
                default: begin
                    // 默认状态
                end
            endcase
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) next_state = CALC;
            end
            
            CALC: begin
                next_state = DONE;
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // 调用递归Karatsuba乘法函数
    karatsuba_16bit karatsuba_core (
        .a(a_reg),
        .b(b_reg),
        .result(mult_result)
    );
    
endmodule

module karatsuba_16bit (
    input [15:0] a,
    input [15:0] b,
    output [31:0] result
);
    wire [7:0] a_high, a_low, b_high, b_low;
    wire [15:0] p1, p2, p3;
    wire [15:0] mid_term;
    wire [31:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[15:8];
    assign a_low = a[7:0];
    assign b_high = b[15:8];
    assign b_low = b[7:0];
    
    // 计算三个子乘积
    karatsuba_8bit k1 (.a(a_high), .b(b_high), .result(p1));
    karatsuba_8bit k2 (.a(a_low), .b(b_low), .result(p2));
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [8:0] a_sum = a_high + a_low;
    wire [8:0] b_sum = b_high + b_low;
    karatsuba_9bit k3 (.a(a_sum), .b(b_sum), .result(p3));
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 16'b0};
    assign term2 = {mid_term, 8'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_9bit (
    input [8:0] a,
    input [8:0] b,
    output [17:0] result
);
    wire [4:0] a_high, b_high;
    wire [3:0] a_low, b_low;
    wire [9:0] p1, p2, p3;
    wire [9:0] mid_term;
    wire [17:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[8:4];
    assign a_low = a[3:0];
    assign b_high = b[8:4];
    assign b_low = b[3:0];
    
    // 计算三个子乘积
    karatsuba_5bit k1 (.a(a_high), .b(b_high), .result(p1));
    karatsuba_4bit k2 (.a(a_low), .b(b_low), .result(p2));
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [5:0] a_sum = a_high + a_low;
    wire [5:0] b_sum = b_high + b_low;
    wire [11:0] p3_full;
    karatsuba_6bit k3 (.a(a_sum), .b(b_sum), .result(p3_full));
    assign p3 = p3_full[9:0]; // 截断为适当的位宽
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 8'b0};
    assign term2 = {mid_term, 4'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] result
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] p1, p2, p3;
    wire [7:0] mid_term;
    wire [15:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // 计算三个子乘积
    karatsuba_4bit k1 (.a(a_high), .b(b_high), .result(p1));
    karatsuba_4bit k2 (.a(a_low), .b(b_low), .result(p2));
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [4:0] a_sum = a_high + a_low;
    wire [4:0] b_sum = b_high + b_low;
    wire [9:0] p3_full;
    karatsuba_5bit k3 (.a(a_sum), .b(b_sum), .result(p3_full));
    assign p3 = p3_full[7:0]; // 截断为适当的位宽
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 8'b0};
    assign term2 = {mid_term, 4'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_6bit (
    input [5:0] a,
    input [5:0] b,
    output [11:0] result
);
    wire [2:0] a_high, a_low, b_high, b_low;
    wire [5:0] p1, p2, p3;
    wire [5:0] mid_term;
    wire [11:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[5:3];
    assign a_low = a[2:0];
    assign b_high = b[5:3];
    assign b_low = b[2:0];
    
    // 计算三个子乘积
    karatsuba_3bit k1 (.a(a_high), .b(b_high), .result(p1));
    karatsuba_3bit k2 (.a(a_low), .b(b_low), .result(p2));
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [3:0] a_sum = a_high + a_low;
    wire [3:0] b_sum = b_high + b_low;
    wire [7:0] p3_full;
    karatsuba_4bit k3 (.a(a_sum), .b(b_sum), .result(p3_full));
    assign p3 = p3_full[5:0]; // 截断为适当的位宽
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 6'b0};
    assign term2 = {mid_term, 3'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_5bit (
    input [4:0] a,
    input [4:0] b,
    output [9:0] result
);
    wire [2:0] a_high;
    wire [1:0] a_low;
    wire [2:0] b_high;
    wire [1:0] b_low;
    wire [5:0] p1, p2;
    wire [6:0] p3_full;
    wire [5:0] p3, mid_term;
    wire [9:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[4:2];
    assign a_low = a[1:0];
    assign b_high = b[4:2];
    assign b_low = b[1:0];
    
    // 计算三个子乘积 - 在这个级别使用直接乘法
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [3:0] a_sum = a_high + a_low;
    wire [3:0] b_sum = b_high + b_low;
    assign p3_full = a_sum * b_sum;
    assign p3 = p3_full[5:0]; // 截断为适当的位宽
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 4'b0};
    assign term2 = {mid_term, 2'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_4bit (
    input [3:0] a,
    input [3:0] b,
    output [7:0] result
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [3:0] mid_term;
    wire [7:0] term1, term2, term3;
    
    // 分割输入数据
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // 基础情况 - 直接乘法
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    
    // 计算(a_high + a_low) * (b_high + b_low)
    wire [2:0] a_sum = a_high + a_low;
    wire [2:0] b_sum = b_high + b_low;
    wire [5:0] p3_full = a_sum * b_sum;
    assign p3 = p3_full[3:0]; // 截断为适当的位宽
    
    // 计算中间项
    assign mid_term = p3 - p1 - p2;
    
    // 组合最终结果
    assign term1 = {p1, 4'b0};
    assign term2 = {mid_term, 2'b0};
    assign term3 = p2;
    assign result = term1 + term2 + term3;
    
endmodule

module karatsuba_3bit (
    input [2:0] a,
    input [2:0] b,
    output [5:0] result
);
    // 对于3位乘法，直接使用乘法器实现
    assign result = a * b;
endmodule