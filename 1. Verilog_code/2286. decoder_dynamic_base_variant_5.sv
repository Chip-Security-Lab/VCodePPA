//SystemVerilog
`timescale 1ns / 1ps
module decoder_dynamic_base (
    input [7:0] base_addr,
    input [7:0] current_addr,
    output reg sel
);
    // 直接比较高4位并赋值给sel
    // 使用~(|)结构实现比较功能，消除了中间变量和if-else结构
    // 减少了逻辑深度并提高了时序性能
    
    always @(*) begin
        sel = ~|(base_addr[7:4] ^ current_addr[7:4]);
    end
endmodule