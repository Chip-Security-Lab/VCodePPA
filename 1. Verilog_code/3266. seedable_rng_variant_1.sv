//SystemVerilog
module seedable_rng (
    input wire clk,
    input wire rst_n,
    input wire load_seed,
    input wire [31:0] seed_value,
    output wire [31:0] random_data
);
    reg [31:0] state_reg;
    reg [31:0] state_p1_reg;
    wire feedback_bit;
    wire [30:0] state_shifted;

    // Pipeline stage 1: Calculate feedback bit and shift state
    assign state_shifted = state_reg[30:0];
    assign feedback_bit = state_reg[31] ^ state_reg[21] ^ state_reg[1] ^ state_reg[0];

    // Pipeline register for intermediate value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_p1_reg <= 32'h1;
        else if (load_seed)
            state_p1_reg <= seed_value;
        else
            state_p1_reg <= {state_shifted, feedback_bit};
    end

    // Main state register to align for output and maintain consistent latency
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_reg <= 32'h1;
        else if (load_seed)
            state_reg <= seed_value;
        else
            state_reg <= state_p1_reg;
    end

    assign random_data = state_reg;
endmodule