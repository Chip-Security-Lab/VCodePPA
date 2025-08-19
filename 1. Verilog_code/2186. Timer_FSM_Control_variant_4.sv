//SystemVerilog
module Timer_FSM_Control (
    input clk, rst, trigger,
    output reg done
);
    // 使用参数替代enum类型
    parameter IDLE = 1'b0, COUNTING = 1'b1;
    
    reg state;
    reg [7:0] cnt;
    
    // 常量补码表示
    wire [7:0] decr_value = 8'hFF; // -1的补码表示
    
    // 带状进位加法器内部信号
    wire [7:0] sum;
    wire [8:0] carry;
    
    // 带状进位加法器实现
    assign carry[0] = 1'b1; // 补码减法需要进位输入为1
    
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_carry_lookahead
            // 生成位(Generate)
            wire g = cnt[i] & decr_value[i];
            // 传播位(Propagate)
            wire p = cnt[i] | decr_value[i];
            
            // 带状进位逻辑
            assign carry[i+1] = g | (p & carry[i]);
            // 计算每一位的和
            assign sum[i] = cnt[i] ^ decr_value[i] ^ carry[i];
        end
    endgenerate
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt <= 8'h00;
            done <= 1'b0;
        end else case(state)
            IDLE: if (trigger) begin
                state <= COUNTING;
                cnt <= 8'd100;
                done <= 1'b0;
            end
            COUNTING: begin
                // 使用带状进位加法器实现的减法
                cnt <= sum;
                done <= (cnt == 8'd1);
                if (cnt == 8'd0) state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule