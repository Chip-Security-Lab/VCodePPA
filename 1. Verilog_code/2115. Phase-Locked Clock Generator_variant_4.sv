//SystemVerilog
module phase_locked_clk(
    input ref_clk,
    input target_clk,
    input rst,
    output reg clk_out,
    output reg locked
);
    reg [1:0] phase_state;
    reg ref_detect, target_detect;
    
    // 优化的加法器逻辑 - 直接计算结果
    wire [1:0] sum;
    wire carry;
    
    // 简化的加法逻辑，减少路径深度
    assign carry = phase_state[0] & 1'b1; // a[0] & b[0], 其中b[0]=1
    assign sum[0] = phase_state[0] ^ 1'b1; // a[0] ^ b[0], 其中b[0]=1
    assign sum[1] = phase_state[1] ^ 1'b0 ^ carry; // a[1] ^ b[1] ^ carry, 其中b[1]=0
    
    // 锁定状态预计算
    wire phase_is_zero = (phase_state == 2'b00);
    wire next_locked = target_detect ? 1'b1 : phase_is_zero;
    
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            ref_detect <= 1'b0;
            phase_state <= 2'b00;
            locked <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            ref_detect <= 1'b1;
            
            // 更新相位状态和锁定状态
            if (target_detect) begin
                phase_state <= 2'b00;
            end else begin
                phase_state <= sum;
            end
            
            locked <= next_locked;
            
            // 时钟输出逻辑
            if (phase_is_zero) begin
                clk_out <= ~clk_out;
            end
        end
    end
    
    always @(posedge target_clk or posedge rst) begin
        if (rst) begin
            target_detect <= 1'b0;
        end else begin
            target_detect <= ref_detect;
        end
    end
endmodule