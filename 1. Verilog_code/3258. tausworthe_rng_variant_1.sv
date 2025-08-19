//SystemVerilog
module tausworthe_rng (
    input clk_in,
    input rst_in,
    output [31:0] rnd_out
);
    reg [31:0] s1_reg, s2_reg, s3_reg;
    wire [31:0] b1_wire, b2_wire, b3_wire;

    // 一级缓冲寄存器
    reg [31:0] s1_buf1, s2_buf1, s3_buf1;
    // 二级缓冲寄存器（用于均衡扇出负载）
    reg [31:0] s1_buf2, s2_buf2, s3_buf2;

    // 计算b1, b2, b3时用缓冲后的信号
    assign b1_wire = ((s1_buf2 << 13) ^ s1_buf2) >> 19;
    assign b2_wire = ((s2_buf2 << 2) ^ s2_buf2) >> 25;
    assign b3_wire = ((s3_buf2 << 3) ^ s3_buf2) >> 11;

    always @(posedge clk_in) begin
        s1_reg  <= rst_in ? 32'h1 : ((s1_buf2 & 32'hFFFFFFFE) ^ b1_wire);
        s2_reg  <= rst_in ? 32'h2 : ((s2_buf2 & 32'hFFFFFFF8) ^ b2_wire);
        s3_reg  <= rst_in ? 32'h4 : ((s3_buf2 & 32'hFFFFFFF0) ^ b3_wire);

        s1_buf1 <= rst_in ? 32'h1 : s1_reg;
        s2_buf1 <= rst_in ? 32'h2 : s2_reg;
        s3_buf1 <= rst_in ? 32'h4 : s3_reg;

        s1_buf2 <= rst_in ? 32'h1 : s1_buf1;
        s2_buf2 <= rst_in ? 32'h2 : s2_buf1;
        s3_buf2 <= rst_in ? 32'h4 : s3_buf1;
    end

    assign rnd_out = s1_buf2 ^ s2_buf2 ^ s3_buf2;

endmodule