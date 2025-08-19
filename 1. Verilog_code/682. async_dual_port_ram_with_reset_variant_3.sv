//SystemVerilog
module parallel_prefix_subtractor #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] diff,
    output wire borrow
);

    // 生成传播和产生信号
    wire [WIDTH-1:0] p, g;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pp
            assign p[i] = a[i] ^ b[i];
            assign g[i] = ~a[i] & b[i];
        end
    endgenerate

    // 并行前缀计算
    wire [WIDTH-1:0] c;
    assign c[0] = 1'b1;  // 初始借位为1
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_carry
            assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
        end
    endgenerate

    // 计算差值和最终借位
    assign diff = p ^ c;
    assign borrow = c[WIDTH-1];

endmodule