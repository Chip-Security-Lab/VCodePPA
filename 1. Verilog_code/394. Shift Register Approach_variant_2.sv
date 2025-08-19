//SystemVerilog
module nand2_14 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    // 直接在时序逻辑中实现 NAND 功能，减少中间信号
    // 这样可以减少路径延迟并优化面积
    always @(posedge clk) begin
        Y <= ~(A & B);
    end
endmodule