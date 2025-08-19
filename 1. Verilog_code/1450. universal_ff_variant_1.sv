//SystemVerilog
module universal_ff (
    input clk, rstn,
    input [1:0] mode,
    input d, j, k, t, s, r,
    output reg q
);
    // 对输入信号进行寄存
    reg [1:0] mode_reg;
    reg d_reg, j_reg, k_reg, t_reg, s_reg, r_reg;
    
    // 将输入寄存到第一级寄存器
    always @(posedge clk) begin
        if (!rstn) begin
            mode_reg <= 2'b00;
            d_reg <= 1'b0;
            j_reg <= 1'b0;
            k_reg <= 1'b0;
            t_reg <= 1'b0;
            s_reg <= 1'b0;
            r_reg <= 1'b0;
        end
        else begin
            mode_reg <= mode;
            d_reg <= d;
            j_reg <= j;
            k_reg <= k;
            t_reg <= t;
            s_reg <= s;
            r_reg <= r;
        end
    end

    // 各模式的下一状态逻辑
    wire jk_next = j_reg & ~q | ~k_reg & q;
    wire t_next = t_reg ^ q;
    wire sr_next = s_reg | (~r_reg & q);
    
    // 根据模式选择下一状态
    reg next_q;
    always @(*) begin
        case(mode_reg)
            2'b00: next_q = d_reg;     // D模式
            2'b01: next_q = jk_next;   // JK模式
            2'b10: next_q = t_next;    // T模式
            2'b11: next_q = sr_next;   // SR模式
            default: next_q = d_reg;   // 默认为D模式
        endcase
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (!rstn) begin
            q <= 1'b0;
        end
        else begin
            q <= next_q;
        end
    end
endmodule