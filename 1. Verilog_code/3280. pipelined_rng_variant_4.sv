//SystemVerilog
// SystemVerilog
module pipelined_rng (
    input wire clk,
    input wire rst_n,
    output wire [31:0] random_data
);

    // Stage registers
    reg [31:0] lfsr_reg;
    reg [31:0] shuffle_reg;
    reg [31:0] nonlinear_reg;

    // Next state wires
    wire [31:0] lfsr_next;
    wire [31:0] shuffle_next;
    wire [31:0] nonlinear_next;

    // Stage 1: LFSR next value calculation
    assign lfsr_next = {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[28] ^ lfsr_reg[15] ^ lfsr_reg[0]};

    // Stage 2: Bit shuffle next value calculation
    assign shuffle_next = {lfsr_reg[15:0], lfsr_reg[31:16]} ^ {shuffle_reg[7:0], shuffle_reg[31:8]};

    // Stage 3: Nonlinear transformation next value calculation
    assign nonlinear_next = shuffle_reg + (nonlinear_reg ^ (nonlinear_reg << 5));

    // =========================================================================
    // Function: LFSR Register Update
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= 32'h12345678;
        else
            lfsr_reg <= lfsr_next;
    end

    // =========================================================================
    // Function: Shuffle Register Update
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shuffle_reg <= 32'h87654321;
        else
            shuffle_reg <= shuffle_next;
    end

    // =========================================================================
    // Function: Nonlinear Register Update
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            nonlinear_reg <= 32'hABCDEF01;
        else
            nonlinear_reg <= nonlinear_next;
    end

    // Output assignment
    assign random_data = nonlinear_reg;

endmodule