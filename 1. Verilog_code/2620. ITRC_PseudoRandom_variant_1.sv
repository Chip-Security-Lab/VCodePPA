//SystemVerilog
module ITRC_PseudoRandom #(
    parameter WIDTH = 8,
    parameter SEED = 32'hA5A5A5A5
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [$clog2(WIDTH)-1:0] selected_int
);
    reg [31:0] lfsr;
    wire [WIDTH-1:0] masked;
    wire [WIDTH-1:0] prefix_propagate;
    wire [WIDTH-1:0] prefix_generate;
    wire [WIDTH-1:0] prefix_carry;
    wire [WIDTH-1:0] priority_bits;

    // LFSR伪随机数生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= SEED;
        end else begin
            lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[20] ^ lfsr[28] ^ lfsr[3]};
        end
    end

    // Masking input with LFSR
    assign masked = int_src & lfsr[WIDTH-1:0];

    // 并行前缀优先级编码器
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_network
            assign prefix_propagate[i] = masked[i];
            assign prefix_generate[i] = masked[i];

            if (i == 0) begin
                assign prefix_carry[i] = prefix_generate[i];
            end else begin
                assign prefix_carry[i] = prefix_generate[i] | (prefix_propagate[i] & prefix_carry[i-1]);
            end

            assign priority_bits[i] = prefix_carry[i] & ~(i > 0 ? prefix_carry[i-1] : 1'b0);
        end
    endgenerate

    // 优先级编码器输出
    always @(*) begin
        selected_int = 0;
        for (int i = 0; i < WIDTH; i = i + 1) begin
            if (priority_bits[i]) selected_int = i;
        end
    end
endmodule