module seedable_rng (
    input wire clk,
    input wire rst_n,
    input wire load_seed,
    input wire [31:0] seed_value,
    output wire [31:0] random_data
);
    reg [31:0] state;
    wire [31:0] next_state;
    
    assign next_state = {state[30:0], state[31] ^ state[21] ^ state[1] ^ state[0]};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= 32'h1;
        else if (load_seed)
            state <= seed_value;
        else
            state <= next_state;
    end
    
    assign random_data = state;
endmodule