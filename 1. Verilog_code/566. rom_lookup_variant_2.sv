//SystemVerilog
module rom_lookup #(parameter N=4)(
    input [N-1:0] x,
    output reg [2**N-1:0] y
);

    wire [N-1:0] x_neg; // 负数表示
    
    assign x_neg = ~x + 1; // 计算x的补码
    
    // 使用桶形移位器实现变量移位
    always @(*) begin
        y = barrel_shifter(1'b1, x_neg);
    end
    
    // 桶形移位器函数
    function [2**N-1:0] barrel_shifter;
        input bit in_bit;
        input [N-1:0] shift_amount;
        
        reg [2**N-1:0] temp;
        integer i;
        
        begin
            temp = {{(2**N-1){1'b0}}, in_bit}; // 初始化为1'b1放在最低位
            
            // 按照桶形移位器的结构实现移位操作
            // 每级移位处理特定的位
            for (i = 0; i < N; i = i + 1) begin
                if (shift_amount[i]) begin
                    temp = temp << (2**i); // 如果当前位为1，左移2^i位
                end
            end
            
            barrel_shifter = temp;
        end
    endfunction

endmodule