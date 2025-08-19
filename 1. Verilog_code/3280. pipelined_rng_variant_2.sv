//SystemVerilog
module pipelined_rng (
    input wire clk,
    input wire rst_n,
    output wire [31:0] random_data
);
    reg [31:0] lfsr_reg, shuffle_reg, nonlinear_reg;
    wire [31:0] lfsr_next, shuffle_next, nonlinear_next;

    // Stage 1: LFSR with path-balanced taps
    wire lfsr_xor1 = lfsr_reg[31] ^ lfsr_reg[28];
    wire lfsr_xor2 = lfsr_reg[15] ^ lfsr_reg[0];
    wire lfsr_xor_final = lfsr_xor1 ^ lfsr_xor2;
    assign lfsr_next = {lfsr_reg[30:0], lfsr_xor_final};

    // Stage 2: Bit shuffle with balanced logic
    wire [15:0] shuffle_upper8 = lfsr_reg[31:24] ^ shuffle_reg[7:0];
    wire [7:0]  shuffle_upper_pad = 8'b0;
    wire [15:0] shuffle_lower8 = lfsr_reg[15:8] ^ shuffle_reg[23:16];
    wire [15:0] shuffle_lower0 = lfsr_reg[7:0] ^ shuffle_reg[15:8];

    wire [15:0] shuffle_upper_result = {shuffle_upper8, shuffle_upper_pad};
    wire [15:0] shuffle_lower_result = {shuffle_lower8, shuffle_lower0};

    assign shuffle_next = {shuffle_upper_result[15:0], shuffle_lower_result[15:0]};

    // Stage 3: Nonlinear transformation with balanced XOR/shift
    wire [31:0] nl_shifted = {nonlinear_reg[26:0], 5'b0};
    wire [31:0] nl_xor_balanced = nonlinear_reg ^ nl_shifted;
    assign nonlinear_next = shuffle_reg + nl_xor_balanced;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 32'h12345678;
            shuffle_reg <= 32'h87654321;
            nonlinear_reg <= 32'hABCDEF01;
        end else begin
            lfsr_reg <= lfsr_next;
            shuffle_reg <= shuffle_next;
            nonlinear_reg <= nonlinear_next;
        end
    end

    assign random_data = nonlinear_reg;
endmodule