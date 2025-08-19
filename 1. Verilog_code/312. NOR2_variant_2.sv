//SystemVerilog
module NOR2 #(parameter W=8) (
    input wire [W-1:0] a, 
    input wire [W-1:0] b, 
    output wire [W-1:0] y
);
    // 直接计算NOR结果，减少数据路径的复杂度
    // 使用De Morgan定律: ~(a | b) = ~a & ~b
    assign y = ~a & ~b;
endmodule