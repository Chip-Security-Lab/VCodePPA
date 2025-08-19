//SystemVerilog
module led_pwm_driver #(parameter W=8)(
    input clk, 
    input [W-1:0] duty,
    output reg pwm_out
);
    reg [W-1:0] cnt;
    wire [W:0] borrow_chain;
    reg [W-1:0] duty_reg; // 寄存输入信号duty
    
    // 先行借位减法器实现
    assign borrow_chain[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : gen_borrow
            assign borrow_chain[i+1] = ((~cnt[i]) & duty_reg[i]) | 
                                      ((~cnt[i] | duty_reg[i]) & borrow_chain[i]);
        end
    endgenerate
    
    // 重定时：将输出寄存器逻辑前移，去除组合逻辑对关键路径的影响
    always @(posedge clk) begin
        cnt <= cnt + 1;
        duty_reg <= duty; // 寄存输入，减少关键路径
        pwm_out <= ~borrow_chain[W]; // 将输出逻辑与计数器更新合并
    end
endmodule