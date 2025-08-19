//SystemVerilog
module fibonacci_lfsr_generator (
    input wire clk_i,
    input wire arst_n_i,
    output wire [31:0] random_o
);
    reg [31:0] lfsr_shift_reg;
    reg feedback_stage1;
    reg feedback_stage2;

    // Pipeline stage 1: partial XOR
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i)
            feedback_stage1 <= 1'b1;
        else
            feedback_stage1 <= lfsr_shift_reg[31] ^ lfsr_shift_reg[21];
    end

    // Pipeline stage 2: complete XOR
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i)
            feedback_stage2 <= 1'b1;
        else
            feedback_stage2 <= feedback_stage1 ^ lfsr_shift_reg[1] ^ lfsr_shift_reg[0];
    end

    // LFSR shift register
    always @(posedge clk_i or negedge arst_n_i) begin
        if (!arst_n_i)
            lfsr_shift_reg <= 32'h1;
        else
            lfsr_shift_reg <= {lfsr_shift_reg[30:0], feedback_stage2};
    end

    assign random_o = lfsr_shift_reg;
endmodule