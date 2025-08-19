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
    reg [WIDTH-1:0] masked;
    reg [WIDTH-1:0] masked_reg;
    reg [$clog2(WIDTH)-1:0] priority_encoded;
    reg [$clog2(WIDTH)-1:0] priority_encoded_reg;
    reg [WIDTH-1:0] inverted_masked;
    reg [WIDTH-1:0] sub_result;
    reg [WIDTH-1:0] sub_result_reg;
    
    // LFSR伪随机数生成
    always @(posedge clk) begin
        if (!rst_n) begin
            lfsr <= SEED;
            masked_reg <= 0;
            priority_encoded_reg <= 0;
            sub_result_reg <= 0;
        end else begin
            lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[20] ^ lfsr[28] ^ lfsr[3]};
            masked_reg <= masked;
            priority_encoded_reg <= priority_encoded;
            sub_result_reg <= sub_result;
        end
    end
    
    // 组合逻辑分割为两级
    always @(*) begin
        masked = int_src & lfsr[WIDTH-1:0];
        inverted_masked = ~masked_reg;
        sub_result = inverted_masked + 1;
    end
    
    // 条件反相减法器实现的优先级编码器
    always @(*) begin
        priority_encoded = 0;
        for (integer i=WIDTH-1; i>=0; i=i-1) begin
            if (sub_result_reg[i]) priority_encoded = i;
        end
        selected_int = priority_encoded_reg;
    end
endmodule