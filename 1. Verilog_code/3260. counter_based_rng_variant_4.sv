//SystemVerilog
module counter_based_rng (
    input wire clk,
    input wire reset,
    input wire [7:0] seed,
    output reg [15:0] rand_out
);
    reg [7:0] counter;

    reg [7:0] next_counter_reg;
    reg [7:0] rand_out_low_reg;
    reg [7:0] rand_out_high_reg;
    reg [7:0] next_rand_low_reg;
    reg [7:0] next_rand_high_reg;

    // Intermediate signals for condition breakdown
    reg [7:0] temp_and_1;
    reg [7:0] temp_and_2;

    always @(*) begin
        // Step 1: Calculate next_counter
        next_counter_reg = counter + 8'h53;

        // Step 2: Extract current rand_out low and high bytes
        rand_out_low_reg  = rand_out[7:0];
        rand_out_high_reg = rand_out[15:8];

        // Step 3: Calculate next_rand_low: (rand_out_low & ~next_counter) | (~rand_out_low & next_counter)
        temp_and_1 = rand_out_low_reg & ~next_counter_reg;
        temp_and_2 = ~rand_out_low_reg & next_counter_reg;
        next_rand_low_reg = temp_and_1 | temp_and_2;

        // Step 4: Calculate next_rand_high: rand_out_high + next_counter
        next_rand_high_reg = rand_out_high_reg + next_counter_reg;
    end

    always @(posedge clk) begin
        if (reset) begin
            counter <= seed;
            rand_out <= {seed, ~seed};
        end else begin
            counter <= next_counter_reg;
            rand_out <= {next_rand_high_reg, next_rand_low_reg};
        end
    end
endmodule