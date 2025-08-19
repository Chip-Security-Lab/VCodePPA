module crypto_rng #(parameter WIDTH = 32, SEED_WIDTH = 16) (
    input wire clock, resetb,
    input wire [SEED_WIDTH-1:0] seed,
    input wire load_seed, get_random,
    output reg [WIDTH-1:0] random_out,
    output reg valid
);
    reg [WIDTH-1:0] state;
    wire [WIDTH-1:0] next_state;
    
    // Non-linear state update function
    assign next_state = {state[WIDTH-2:0], state[WIDTH-1]} ^ 
                       (state + {state[7:0], state[WIDTH-1:8]});
    
    always @(posedge clock or negedge resetb) begin
        if (!resetb) begin
            state <= {WIDTH{1'b1}};
            valid <= 0;
        end else if (load_seed) begin
            state <= {seed, seed};
            valid <= 0;
        end else if (get_random) begin
            state <= next_state;
            random_out <= state ^ next_state;
            valid <= 1;
        end else valid <= 0;
    end
endmodule