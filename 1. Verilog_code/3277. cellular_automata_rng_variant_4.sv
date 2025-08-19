//SystemVerilog
module cellular_automata_rng (
    input wire clk,
    input wire rst,
    output wire [15:0] random_value
);
    reg [15:0] ca_state;
    wire [15:0] next_state;

    // Unrolled Rule 30 cellular automaton logic
    assign next_state[0]  = ca_state[15] ^ (ca_state[0]  | ca_state[1]);
    assign next_state[1]  = ca_state[0]  ^ (ca_state[1]  | ca_state[2]);
    assign next_state[2]  = ca_state[1]  ^ (ca_state[2]  | ca_state[3]);
    assign next_state[3]  = ca_state[2]  ^ (ca_state[3]  | ca_state[4]);
    assign next_state[4]  = ca_state[3]  ^ (ca_state[4]  | ca_state[5]);
    assign next_state[5]  = ca_state[4]  ^ (ca_state[5]  | ca_state[6]);
    assign next_state[6]  = ca_state[5]  ^ (ca_state[6]  | ca_state[7]);
    assign next_state[7]  = ca_state[6]  ^ (ca_state[7]  | ca_state[8]);
    assign next_state[8]  = ca_state[7]  ^ (ca_state[8]  | ca_state[9]);
    assign next_state[9]  = ca_state[8]  ^ (ca_state[9]  | ca_state[10]);
    assign next_state[10] = ca_state[9]  ^ (ca_state[10] | ca_state[11]);
    assign next_state[11] = ca_state[10] ^ (ca_state[11] | ca_state[12]);
    assign next_state[12] = ca_state[11] ^ (ca_state[12] | ca_state[13]);
    assign next_state[13] = ca_state[12] ^ (ca_state[13] | ca_state[14]);
    assign next_state[14] = ca_state[13] ^ (ca_state[14] | ca_state[15]);
    assign next_state[15] = ca_state[14] ^ (ca_state[15] | ca_state[0]);

    always @(posedge clk) begin
        ca_state <= rst ? 16'h8001 : next_state;
    end

    assign random_value = ca_state;
endmodule