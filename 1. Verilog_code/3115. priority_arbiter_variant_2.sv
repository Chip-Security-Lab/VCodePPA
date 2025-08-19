//SystemVerilog
module priority_arbiter(
    input wire clk,
    input wire reset,
    input wire [3:0] requests,
    input wire [3:0] multiplicand,  // 新增乘法输入
    input wire [3:0] multiplier,    // 新增乘法输入
    output reg [3:0] grant,
    output reg busy,
    output reg [7:0] product        // 新增乘法结果输出
);
    parameter [1:0] IDLE = 2'b00, GRANT0 = 2'b01, GRANT1 = 2'b10, GRANT2 = 2'b11;
    reg [1:0] state, next_state;
    
    // Karatsuba乘法器信号
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [7:0] karatsuba_result;
    
    // 将4位操作数分为高2位和低2位
    assign a_high = multiplicand[3:2];
    assign a_low = multiplicand[1:0];
    assign b_high = multiplier[3:2];
    assign b_low = multiplier[1:0];
    
    // Karatsuba乘法计算
    // P1 = a_high * b_high
    // P2 = a_low * b_low
    // P3 = (a_high + a_low) * (b_high + b_low) - P1 - P2
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    assign p3 = (a_high + a_low) * (b_high + b_low) - (a_high * b_high) - (a_low * b_low);
    
    // 组合结果: P1 << 4 + P3 << 2 + P2
    assign karatsuba_result = {p1, 4'b0000} + {2'b00, p3, 2'b00} + {4'b0000, p2};
    
    // 状态寄存器更新逻辑 - 分离出状态转移
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态组合逻辑 - 分离出状态判断
    always @(*) begin
        case (requests)
            4'b0000: next_state = IDLE;
            default: begin
                if (requests[0])
                    next_state = GRANT0;
                else if (requests[1])
                    next_state = GRANT1;
                else if (requests[2])
                    next_state = GRANT2;
                else
                    next_state = 2'b11; // GRANT3
            end
        endcase
    end
    
    // 输出grant信号逻辑 - 分离输出逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            grant <= 4'b0000;
        end else begin
            case (next_state)
                IDLE:   grant <= 4'b0000;
                GRANT0: grant <= 4'b0001;
                GRANT1: grant <= 4'b0010;
                GRANT2: grant <= 4'b0100;
                default: grant <= 4'b1000;
            endcase
        end
    end
    
    // busy信号逻辑 - 进一步分离输出逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 1'b0;
        end else begin
            busy <= (next_state != IDLE);
        end
    end
    
    // 乘法结果寄存器
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            product <= 8'b0;
        end else begin
            product <= karatsuba_result;
        end
    end
endmodule