//SystemVerilog
module seedable_rng (
    input wire clk,
    input wire rst_n,
    input wire load_seed,
    input wire [31:0] seed_value,
    output wire [31:0] random_data
);
    reg [31:0] state;
    wire feedback;
    reg [31:0] lfsr_lut [0:15];
    wire [3:0] lut_index;
    wire [3:0] lut_feedback;

    // Precompute LUT for feedback calculation: state[31], state[21], state[1], state[0]
    initial begin
        lfsr_lut[ 0] = 0; lfsr_lut[ 1] = 1; lfsr_lut[ 2] = 1; lfsr_lut[ 3] = 0;
        lfsr_lut[ 4] = 1; lfsr_lut[ 5] = 0; lfsr_lut[ 6] = 0; lfsr_lut[ 7] = 1;
        lfsr_lut[ 8] = 1; lfsr_lut[ 9] = 0; lfsr_lut[10] = 0; lfsr_lut[11] = 1;
        lfsr_lut[12] = 0; lfsr_lut[13] = 1; lfsr_lut[14] = 1; lfsr_lut[15] = 0;
    end

    assign lut_index = {state[31], state[21], state[1], state[0]};
    assign feedback  = lfsr_lut[lut_index][0];
    assign random_data = state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 32'h1;
        else if (load_seed)
            state <= seed_value;
        else
            state <= {state[30:0], feedback};
    end
endmodule