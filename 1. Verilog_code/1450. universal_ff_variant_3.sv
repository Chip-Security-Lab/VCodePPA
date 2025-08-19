//SystemVerilog
module universal_ff (
    input clk, rstn,
    input [1:0] mode,
    input d, j, k, t, s, r,
    output reg q
);
    // 寄存输入信号
    reg [1:0] mode_reg;
    reg d_reg, j_reg, k_reg, t_reg, s_reg, r_reg;
    reg q_feedback;
    
    // 寄存输入信号
    always @(posedge clk) begin
        if (!rstn) begin
            mode_reg <= 2'b00;
            d_reg <= 1'b0;
            j_reg <= 1'b0;
            k_reg <= 1'b0;
            t_reg <= 1'b0;
            s_reg <= 1'b0;
            r_reg <= 1'b0;
            q_feedback <= 1'b0;
        end else begin
            mode_reg <= mode;
            d_reg <= d;
            j_reg <= j;
            k_reg <= k;
            t_reg <= t;
            s_reg <= s;
            r_reg <= r;
            q_feedback <= q;
        end
    end
    
    // 基于寄存的输入信号计算下一状态
    always @(posedge clk) begin
        if (!rstn) begin
            q <= 1'b0;
        end else begin
            case(mode_reg)
                2'b00: q <= d_reg;                       // D模式
                2'b01: q <= j_reg&~q_feedback | ~k_reg&q_feedback;  // JK模式
                2'b10: q <= t_reg^q_feedback;           // T模式
                2'b11: q <= s_reg | (~r_reg & q_feedback);  // SR模式
                default: q <= q_feedback;
            endcase
        end
    end
endmodule