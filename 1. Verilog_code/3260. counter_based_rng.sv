module counter_based_rng (
    input wire clk,
    input wire reset,
    input wire [7:0] seed,
    output reg [15:0] rand_out
);
    reg [7:0] counter;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= seed;
            rand_out <= {seed, ~seed};
        end else begin
            counter <= counter + 8'h53;
            rand_out <= {rand_out[7:0] ^ counter, rand_out[15:8] + counter};
        end
    end
endmodule