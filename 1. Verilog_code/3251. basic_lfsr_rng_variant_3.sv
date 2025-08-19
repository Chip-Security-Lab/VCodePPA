//SystemVerilog
module basic_lfsr_rng (
    input wire clk,
    input wire rst_n,
    output wire [15:0] random_out
);
    wire feedback_bit;
    wire [15:0] lfsr_next;
    reg  [15:0] lfsr_reg;

    // 简化后的LFSR反馈计算
    assign feedback_bit = lfsr_reg[15] ^ lfsr_reg[13] ^ (lfsr_reg[12] ^ lfsr_reg[10]);
    assign lfsr_next    = {lfsr_reg[14:0], feedback_bit};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= 16'hACE1;
        else
            lfsr_reg <= lfsr_next;
    end

    assign random_out = lfsr_reg;
endmodule