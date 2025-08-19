//SystemVerilog
module divider_8bit_with_overflow (
    input [7:0] a,
    input [7:0] b,
    output [7:0] quotient,
    output [7:0] remainder,
    output overflow
);

    // 检测除数为零
    wire zero_divisor;
    assign zero_divisor = (b == 8'b00000000);
    
    // 不恢复余数除法器实现
    reg [7:0] q_reg;
    reg [8:0] r_reg;
    reg [7:0] b_reg;
    reg [7:0] a_reg;
    reg [3:0] count;
    reg div_done;
    
    // 初始化寄存器
    always @(*) begin
        a_reg = a;
        b_reg = b;
    end
    
    // 不恢复余数除法算法实现
    always @(*) begin
        // 初始化
        r_reg = {1'b0, a_reg};
        q_reg = 8'b0;
        count = 4'b0;
        div_done = 1'b0;
        
        // 如果除数为零，直接返回
        if (zero_divisor) begin
            q_reg = 8'b0;
            r_reg = 9'b0;
            div_done = 1'b1;
        end
        else begin
            // 不恢复余数除法算法
            for (count = 0; count < 8; count = count + 1) begin
                // 左移余数
                r_reg = {r_reg[7:0], 1'b0};
                
                // 如果余数大于等于除数，则商加1，余数减去除数
                if (r_reg >= {1'b0, b_reg}) begin
                    q_reg[7-count] = 1'b1;
                    r_reg = r_reg - {1'b0, b_reg};
                end
                else begin
                    q_reg[7-count] = 1'b0;
                end
            end
            
            div_done = 1'b1;
        end
    end
    
    // 输出赋值
    assign quotient = zero_divisor ? 8'b00000000 : q_reg;
    assign remainder = zero_divisor ? 8'b00000000 : r_reg[7:0];
    assign overflow = zero_divisor;

endmodule