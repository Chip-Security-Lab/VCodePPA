//SystemVerilog
module redun_logic_xnor (
    input      clk,    
    input      rst_n,   
    input      a,
    input      b, 
    input      c,
    input      d,
    output reg y
);

    // 寄存器化的输入信号（前向寄存器重定时）
    reg a_reg, b_reg, c_reg, d_reg;
    
    // 输入信号寄存器化，将寄存器移到了更靠近输入端
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
            c_reg <= 1'b0;
            d_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
        end
    end

    // 中间计算结果寄存器
    reg ab_xnor_reg, cd_xnor_reg;
    
    // 第一级组合逻辑，计算XNOR而不是XOR，直接计算~(a^b)和~(c^d)
    // 这样可以减少一级逻辑深度
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_xnor_reg <= 1'b0;
            cd_xnor_reg <= 1'b0;
        end else begin
            ab_xnor_reg <= ~(a_reg ^ b_reg);
            cd_xnor_reg <= ~(c_reg ^ d_reg);
        end
    end
    
    // 输出寄存器 - 根据XNOR等价性质：~(a^b^c^d) = ~(a^b)^~(c^d)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= ab_xnor_reg ^ cd_xnor_reg;
        end
    end

endmodule