//SystemVerilog
module parity_ring_counter(
    input wire clk,
    input wire rst_n,
    output reg [3:0] count,
    output reg parity
);
    // 使用寄存器实现奇偶校验，减少组合逻辑路径
    always @(posedge clk or negedge rst_n) begin
        count <= (!rst_n) ? 4'b0001 : {count[2:0], count[3]};
        parity <= (!rst_n) ? 1'b1 : (parity ^ (count[3] ^ count[0]));
    end
endmodule