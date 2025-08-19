//SystemVerilog
module rng_poly_8(
    input                 clk,
    input                 en,
    output reg [11:0]     r_out
);
    // 初始化输出寄存器
    initial r_out = 12'hABC;

    // 优化后的反馈生成逻辑：直接组合异或，减少中间节点和层级
    wire feedback = r_out[11] ^ r_out[9] ^ r_out[6] ^ r_out[3];

    always @(posedge clk) begin
        if(en)
            r_out <= {r_out[10:0], feedback};
    end
endmodule