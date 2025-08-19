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
    integer i;
    reg [$clog2(WIDTH)-1:0] priority_encoded;
    
    // LFSR伪随机数生成
    always @(posedge clk) begin
        if (!rst_n) lfsr <= SEED;
        else lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[20] ^ lfsr[28] ^ lfsr[3]};
    end
    
    assign masked = int_src & lfsr[WIDTH-1:0];
    
    // 实现优先级编码器 - 寻找最高位为1的位置
    always @(*) begin
        priority_encoded = 0;
        for (i=WIDTH-1; i>=0; i=i-1) begin
            if (masked[i]) priority_encoded = i;
        end
        selected_int = priority_encoded;
    end
endmodule