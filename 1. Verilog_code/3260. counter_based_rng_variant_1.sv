//SystemVerilog
module counter_based_rng (
    input wire clk,
    input wire reset,
    input wire [7:0] seed,
    output reg [15:0] rand_out
);
    reg [7:0] counter;
    wire [7:0] next_counter;
    wire [7:0] sum_rand_high;

    // Optimized 8-bit adder for counter + 8'h53
    assign next_counter = counter + 8'h53;

    // Optimized 8-bit adder for rand_out[15:8] + counter
    assign sum_rand_high = rand_out[15:8] + counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= seed;
            rand_out <= {seed, ~seed};
        end else begin
            counter <= next_counter;
            rand_out <= {rand_out[7:0] ^ counter, sum_rand_high};
        end
    end
endmodule