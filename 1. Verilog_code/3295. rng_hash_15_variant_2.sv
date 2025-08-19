//SystemVerilog
// rng_hash_15_top: 顶层模块，集成LFSR和XOR位生成子模块
module rng_hash_15(
    input             clk,
    input             rst_n,
    input             enable,
    output [7:0]      out_v
);

    wire [7:0]        lfsr_state;
    wire              xor_bit;

    // LFSR寄存器子模块
    lfsr_reg u_lfsr_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (enable),
        .feedback   (xor_bit),
        .lfsr_out   (lfsr_state)
    );

    // XOR反馈位生成子模块
    lfsr_feedback u_lfsr_feedback (
        .lfsr_in    (lfsr_state),
        .xor_bit    (xor_bit)
    );

    assign out_v = lfsr_state;

endmodule

// lfsr_reg: 8位线性反馈移位寄存器，支持异步复位和使能控制
module lfsr_reg (
    input           clk,
    input           rst_n,
    input           enable,
    input           feedback,
    output reg [7:0] lfsr_out
);
    // 复位时输出初始值，移位时插入反馈位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_out <= 8'hD2;
        end else if (enable) begin
            lfsr_out <= {lfsr_out[6:0], feedback};
        end
    end
endmodule

// lfsr_feedback: 生成LFSR的反馈位，按掩码与后异或
module lfsr_feedback (
    input  [7:0] lfsr_in,
    output       xor_bit
);
    // 仅选取掩码A3对应位进行异或
    assign xor_bit = ^(lfsr_in & 8'hA3);
endmodule