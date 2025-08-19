//SystemVerilog - IEEE 1364-2005
module parallel_arbiter #(parameter WIDTH=8) (
    input [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // 优化比较链路，实现更高效的优先级编码
    // 直接使用位操作获取最高优先级请求
    // 公式: grant = req & (~req + 1)，可得到最低位的1
    
    // 简化实现，无需中间变量
    assign grant_o = req_i & (-req_i);
    
endmodule