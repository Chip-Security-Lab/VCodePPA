//SystemVerilog
module rom_lookup #(parameter N=4)(
    input [N-1:0] x,
    output reg [2**N-1:0] y
);
    wire [N-1:0] x_complement; // 补码表示
    assign x_complement = ~x + 1; // 计算x的补码

    always @(*) begin
        y = 1 << x_complement; // 使用补码加法实现减法
    end
endmodule