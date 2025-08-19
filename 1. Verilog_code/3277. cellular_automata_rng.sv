module cellular_automata_rng (
    input wire clk,
    input wire rst,
    output wire [15:0] random_value
);
    reg [15:0] ca_state;
    wire [15:0] next_state;
    
    // Rule 30 cellular automaton
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : rule30_gen
            if (i == 0)
                assign next_state[i] = ca_state[15] ^ (ca_state[0] | ca_state[1]);
            else if (i == 15)
                assign next_state[i] = ca_state[14] ^ (ca_state[15] | ca_state[0]);
            else
                assign next_state[i] = ca_state[i-1] ^ (ca_state[i] | ca_state[i+1]);
        end
    endgenerate
    
    always @(posedge clk) begin
        if (rst)
            ca_state <= 16'h8001;
        else
            ca_state <= next_state;
    end
    
    assign random_value = ca_state;
endmodule