//SystemVerilog
module CombDiv(
    input [3:0] D, d,
    output [3:0] q
);
    reg [3:0] q_reg;
    
    always @(*) begin
        if (d == 0) begin
            // 处理除数为0的情况
            q_reg = 0;
        end else begin
            // 使用移位和减法实现的优化除法算法
            // 通过二进制长除法计算商
            q_reg = (D >= (d << 3)) ? 4'b1000 : 4'b0000;
            
            q_reg = q_reg | ((D - (q_reg[3] ? (d << 3) : 4'b0)) >= (d << 2) ? 4'b0100 : 4'b0000);
            
            q_reg = q_reg | ((D - (q_reg[3] ? (d << 3) : 4'b0) - (q_reg[2] ? (d << 2) : 4'b0)) >= (d << 1) ? 4'b0010 : 4'b0000);
            
            q_reg = q_reg | ((D - (q_reg[3] ? (d << 3) : 4'b0) - (q_reg[2] ? (d << 2) : 4'b0) - 
                             (q_reg[1] ? (d << 1) : 4'b0)) >= d ? 4'b0001 : 4'b0000);
        end
    end
    
    assign q = q_reg;
endmodule