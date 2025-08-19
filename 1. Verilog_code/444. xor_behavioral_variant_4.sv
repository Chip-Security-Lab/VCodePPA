//SystemVerilog
module booth_multiplier_8bit(
    input [7:0] multiplicand, multiplier,
    input clk, rst_n, start,
    output reg done,
    output reg [15:0] product
);
    // 控制状态
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [3:0] count;
    reg [7:0] M; // 被乘数
    reg [16:0] A; // 累加寄存器和乘数以及额外位
    reg [1:0] booth_bits;
    
    // 状态机控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (count == 4'd8) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 计数器和数据处理
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            count <= 4'd0;
            M <= 8'd0;
            A <= 17'd0;
            done <= 1'b0;
            product <= 16'd0;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        M <= multiplicand;
                        A <= {8'd0, multiplier, 1'b0}; // {A, Q, q-1}
                        count <= 4'd0;
                        done <= 1'b0;
                    end
                end
                
                CALC: begin
                    // Booth算法编码检查最低两位
                    booth_bits = A[1:0];
                    case (booth_bits)
                        2'b01: A[16:9] = A[16:9] + M; // +M
                        2'b10: A[16:9] = A[16:9] - M; // -M
                        default: ; // 00或11不做操作
                    endcase
                    
                    // 算术右移
                    A = {A[16], A[16:1]};
                    count <= count + 1'b1;
                end
                
                DONE: begin
                    product <= A[16:1]; // 结果存在A[16:1]
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule

// XOR模块保持不变，为了保持接口兼容性
module xor_behavioral(input a, b, output reg y);
    always @(*) begin
        y = a ^ b;
    end
endmodule