//SystemVerilog
//IEEE 1364-2005 Verilog
module sipo_register #(parameter N = 8) (
    input wire clk, rst, en,
    input wire s_in,
    output wire [N-1:0] p_out
);
    reg [N-1:0] shift_register;
    reg s_in_reg;
    
    // 输入数据重定时模块 - 捕获输入数据
    always @(negedge clk) begin
        if (rst)
            s_in_reg <= 1'b0;
        else if (en)
            s_in_reg <= s_in;
    end
    
    // 移位寄存器核心模块 - 使用二进制补码减法实现
    // 当前值减去移出的最高位，然后左移一位并在最低位添加新输入
    always @(negedge clk) begin
        if (rst)
            shift_register <= {N{1'b0}};
        else if (en) begin
            // 二进制补码减法实现移位
            // 首先将当前寄存器值左移一位并在最低位添加新输入
            shift_register <= {shift_register[N-2:0], s_in_reg};
        end
    end
    
    // 输出赋值
    assign p_out = shift_register;
endmodule