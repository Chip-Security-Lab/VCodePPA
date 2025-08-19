//SystemVerilog
module Gen_XNOR(
    input [15:0] vec1, vec2,
    output [15:0] result
);
    // 中间变量定义
    reg [15:0] p_reg, g_reg;
    reg [16:0] c_reg;
    reg [15:0] result_reg;
    
    integer i;
    
    // 组合逻辑实现
    always @(*) begin
        // 初始化进位
        c_reg[0] = 1'b1;
        
        // 计算传播和生成信号
        for (i = 0; i < 16; i = i + 1) begin
            // 使用case语句替代if-else级联
            case ({vec1[i], vec2[i]})
                2'b11: begin // 两个输入都为1
                    p_reg[i] = 1'b1;
                    g_reg[i] = 1'b1;
                end
                2'b10, 2'b01: begin // 至少一个输入为1
                    p_reg[i] = 1'b1;
                    g_reg[i] = 1'b0;
                end
                2'b00: begin // 两个输入都为0
                    p_reg[i] = 1'b0;
                    g_reg[i] = 1'b0;
                end
            endcase
            
            // 计算进位，使用case语句
            case ({g_reg[i], p_reg[i], c_reg[i]})
                3'b1??: begin // 当生成信号为1时，进位一定为1
                    c_reg[i+1] = 1'b1;
                end
                3'b011: begin // 当传播信号为1且前一位进位为1时，进位为1
                    c_reg[i+1] = 1'b1;
                end
                default: begin // 其他情况进位为0
                    c_reg[i+1] = 1'b0;
                end
            endcase
        end
        
        // 计算结果
        for (i = 0; i < 16; i = i + 1) begin
            // 使用case语句替代if-else级联
            case ({p_reg[i], g_reg[i], c_reg[i]})
                3'b100: begin // 传播为1，生成为0，前一位进位为0
                    result_reg[i] = 1'b1;
                end
                3'b101: begin // 传播为1，生成为0，前一位进位为1
                    result_reg[i] = 1'b0;
                end
                3'b??0: begin // 其他情况，前一位进位为0
                    result_reg[i] = 1'b0;
                end
                default: begin // 其他情况，前一位进位为1
                    result_reg[i] = 1'b1;
                end
            endcase
        end
    end
    
    // 连续赋值
    assign result = result_reg;
    
endmodule