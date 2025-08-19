//SystemVerilog
// IEEE 1364-2005 Verilog标准
module GatedClockShift #(parameter BITS=8) (
    input gclk,  // 门控时钟
    input en, s_in,
    output [BITS-1:0] q
);
    // 在输入端注册使能信号和输入数据
    reg en_reg;
    reg s_in_reg;
    
    // 输出寄存器
    reg [BITS-1:0] q_reg;
    
    always @(posedge gclk) begin
        // 捕获输入信号
        en_reg <= en;
        s_in_reg <= s_in;
        
        // 根据寄存后的使能信号执行移位操作
        if (en_reg) begin
            // 使用补码加法实现移位操作 (左移等效于加上自身)
            q_reg <= q_reg + q_reg;
            // 如果需要在LSB位加入输入位
            q_reg[0] <= s_in_reg;
        end
    end
    
    // 连接输出
    assign q = q_reg;
    
endmodule