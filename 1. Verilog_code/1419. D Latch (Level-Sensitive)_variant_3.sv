//SystemVerilog
module d_latch (
    input wire enable,
    input wire d,
    output reg q
);
    // 使用阻塞赋值和明确的else路径以提高综合效率
    always @(*) begin
        if (enable)
            q = d;
        // 显式指定锁存行为，避免隐式锁存
        // else q保持原值
    end
endmodule

module booth_multiplier_8bit (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] multiplicand,  // 被乘数
    input wire [7:0] multiplier,    // 乘数
    output reg [15:0] product,      // 乘积结果
    output reg done                 // 完成标志
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] M;                     // 被乘数寄存器
    reg [15:0] A;                    // 累加器
    reg [7:0] Q;                     // 乘数寄存器
    reg Q_1;                         // 乘数的额外一位
    reg [3:0] count;                 // 计数器
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (count == 8) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M <= 8'b0;
            A <= 16'b0;
            Q <= 8'b0;
            Q_1 <= 1'b0;
            count <= 4'b0;
            product <= 16'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        M <= multiplicand;
                        A <= 16'b0;
                        Q <= multiplier;
                        Q_1 <= 1'b0;
                        count <= 4'b0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    // Booth算法 - 检查乘数的最后两位
                    case ({Q[0], Q_1})
                        2'b01: A <= A + {M, 8'b0};     // +M
                        2'b10: A <= A - {M, 8'b0};     // -M
                        default: A <= A;               // 无操作
                    endcase
                    
                    // 算术右移
                    {A, Q, Q_1} <= {A[15], A, Q};
                    count <= count + 1;
                end
                
                DONE: begin
                    product <= {A[7:0], Q};
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule