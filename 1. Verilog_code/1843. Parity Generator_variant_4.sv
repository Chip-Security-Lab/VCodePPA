//SystemVerilog
// SystemVerilog
module parity_generator #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] data_i,
    input  wire             odd_parity,  // 0=even, 1=odd
    output wire             parity_bit
);
    // 使用循环结构计算奇偶校验，改善时序和资源利用
    reg parity_calc;
    
    always_comb begin
        parity_calc = 1'b0;
        for (int i = 0; i < WIDTH; i++) begin
            parity_calc = parity_calc ^ data_i[i];
        end
    end
    
    // 最终结果需要考虑奇偶校验类型
    assign parity_bit = parity_calc ^ odd_parity;
endmodule