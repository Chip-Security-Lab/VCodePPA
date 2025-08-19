//SystemVerilog
module divider_16bit (
    input [15:0] dividend,
    input [15:0] divisor,
    input clk,
    input rst_n,
    input start,
    output reg [15:0] quotient,
    output reg [15:0] remainder,
    output reg overflow,
    output reg done
);

    // FSM states
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] dividend_reg, divisor_reg;
    reg [31:0] partial_rem; // 32位部分余数寄存器
    reg [4:0] count; // 计数器，最多需要16次迭代
    
    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = start ? (divisor == 0 ? DONE : CALC) : IDLE;
            CALC: next_state = (count == 0) ? DONE : CALC;
            DONE: next_state = start ? IDLE : DONE;
            default: next_state = IDLE;
        endcase
    end
    
    // Datapath
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 16'b0;
            divisor_reg <= 16'b0;
            partial_rem <= 32'b0;
            count <= 5'd0;
            quotient <= 16'b0;
            remainder <= 16'b0;
            overflow <= 1'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        dividend_reg <= dividend;
                        divisor_reg <= divisor;
                        partial_rem <= {16'b0, dividend};
                        count <= 5'd16; // 16次迭代
                        done <= 1'b0;
                        
                        if (divisor == 0) begin
                            overflow <= 1'b1;
                            quotient <= 16'b0;
                            remainder <= 16'b0;
                        end else begin
                            overflow <= 1'b0;
                        end
                    end
                end
                
                CALC: begin
                    // 执行二进制长除法的一步
                    partial_rem <= partial_rem[30:0] << 1; // 左移一位
                    count <= count - 1'b1;
                    
                    // 尝试减去除数
                    if (partial_rem[31:16] >= divisor_reg) begin
                        partial_rem[31:16] <= partial_rem[31:16] - divisor_reg;
                        partial_rem[0] <= 1'b1; // 设置商的当前位为1
                    end
                end
                
                DONE: begin
                    quotient <= partial_rem[15:0]; // 最终商
                    remainder <= partial_rem[31:16]; // 最终余数
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule