module neg_edge_ring_counter #(parameter BITS = 4)(
    input wire clock,
    output reg [BITS-1:0] state
);
    initial state = 4'b0001;
    
    always @(negedge clock) begin
        state <= {state[BITS-2:0], state[BITS-1]};
    end
endmodule