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
    reg [31:0] lfsr_next;
    wire [WIDTH-1:0] masked;
    reg [WIDTH-1:0] priority_lut [0:WIDTH-1];
    reg [WIDTH-1:0] masked_reg;
    reg [$clog2(WIDTH)-1:0] selected_int_next;
    integer i;
    
    // LFSR伪随机数生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= SEED;
            masked_reg <= 0;
            selected_int <= 0;
        end else begin
            lfsr <= lfsr_next;
            masked_reg <= int_src & lfsr[WIDTH-1:0];
            selected_int <= selected_int_next;
        end
    end

    // 组合逻辑分割为两级
    always @(*) begin
        lfsr_next = {lfsr[30:0], lfsr[31] ^ lfsr[20] ^ lfsr[28] ^ lfsr[3]};
        selected_int_next = 0;
        for (i=WIDTH-1; i>=0; i=i-1) begin
            if (masked_reg & priority_lut[i]) begin
                selected_int_next = i;
            end
        end
    end
    
    // 初始化查找表
    initial begin
        for (i=0; i<WIDTH; i=i+1) begin
            priority_lut[i] = 1 << i;
        end
    end
endmodule