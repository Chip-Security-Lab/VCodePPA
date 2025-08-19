//SystemVerilog
module configurable_parity #(
    parameter WIDTH = 8
)(
    input clk,
    input cfg_parity_type, // 0: even, 1: odd
    input [WIDTH-1:0] data,
    output reg parity
);
    wire [WIDTH-1:0] complement_data;
    wire [WIDTH:0] borrow;
    wire calc_parity;
    
    // 使用借位减法器算法实现奇偶校验 
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 实现借位减法器链
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: borrow_subtractor
            assign complement_data[i] = ~data[i];
            assign borrow[i+1] = (~data[i] & borrow[i]) | (~data[i] & 1'b1) | (borrow[i] & 1'b1);
        end
    endgenerate
    
    // 最终的借位值反映了奇偶校验
    assign calc_parity = borrow[WIDTH];
    
    // 根据配置选择奇偶校验类型
    always @(posedge clk) begin
        parity <= cfg_parity_type ? calc_parity : ~calc_parity;
    end
endmodule