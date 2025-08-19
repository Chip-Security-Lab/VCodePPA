//SystemVerilog
module divider_8bit (
    input clk,
    input rst_n,
    
    // 输入接口 - Valid-Ready握手
    input [7:0] dividend,
    input [7:0] divisor,
    input valid_in,
    output reg ready_in,
    
    // 输出接口 - Valid-Ready握手
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg valid_out,
    input ready_out
);

    // 内部寄存器和状态定义
    reg [7:0] q, r, d;
    reg [3:0] i;
    reg [8:0] p; // 部分余数
    reg [7:0] dividend_reg, divisor_reg;
    
    // 状态机定义
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state, next_state;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态机和数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend_reg <= 8'b0;
            divisor_reg <= 8'b0;
            q <= 8'b0;
            r <= 8'b0;
            i <= 4'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    ready_in <= 1'b1;
                    if (valid_in && ready_in) begin
                        dividend_reg <= dividend;
                        divisor_reg <= divisor;
                        ready_in <= 1'b0;
                        q <= 8'b0;
                        r <= 8'b0;
                        i <= 4'b0;
                    end
                end
                
                COMPUTE: begin
                    if (i < 8) begin
                        // 将商的最高位左移进部分余数
                        r <= {r[6:0], dividend_reg[7-i]};
                        
                        // 计算部分余数减去除数
                        p <= {1'b0, r} - {1'b0, divisor_reg};
                        
                        if (!p[8]) begin // 如果部分余数为正(p[8]是符号位)
                            r <= p[7:0];  // 更新部分余数
                            q[7-i] <= 1;  // 设置商的当前位为1
                        end else begin
                            q[7-i] <= 0;  // 设置商的当前位为0
                            // 部分余数保持不变
                        end
                        
                        i <= i + 1;
                    end
                end
                
                DONE: begin
                    valid_out <= 1'b1;
                    if (valid_out && ready_out) begin
                        valid_out <= 1'b0;
                        ready_in <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // 组合逻辑 - 计算下一个状态
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE:
                if (valid_in && ready_in)
                    next_state = COMPUTE;
            
            COMPUTE:
                if (i >= 8)
                    next_state = DONE;
            
            DONE:
                if (valid_out && ready_out)
                    next_state = IDLE;
        endcase
    end
    
    // 输出逻辑
    always @(*) begin
        if (state == DONE) begin
            quotient = q;
            remainder = r;
        end else begin
            quotient = 8'b0;
            remainder = 8'b0;
        end
    end

endmodule