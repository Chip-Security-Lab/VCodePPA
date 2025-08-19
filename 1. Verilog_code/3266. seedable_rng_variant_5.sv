//SystemVerilog
module seedable_rng (
    input wire clk,
    input wire rst_n,
    input wire load_seed,
    input wire [31:0] seed_value,
    output wire [31:0] random_data
);
    reg [31:0] lfsr_state_reg;
    wire [31:0] lfsr_next_state;

    assign lfsr_next_state = {lfsr_state_reg[30:0], lfsr_state_reg[31] ^ lfsr_state_reg[21] ^ lfsr_state_reg[1] ^ lfsr_state_reg[0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_state_reg <= 32'h1;
        end else if (load_seed) begin
            lfsr_state_reg <= seed_value;
        end else begin
            lfsr_state_reg <= lfsr_next_state;
        end
    end

    assign random_data = lfsr_state_reg;
endmodule