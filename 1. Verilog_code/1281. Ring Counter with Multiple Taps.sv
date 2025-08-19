module tapped_ring_counter(
    input wire clock,
    input wire reset,
    output reg [3:0] state,
    output wire tap1, tap2 // Tapped outputs
);
    assign tap1 = state[1];
    assign tap2 = state[3];
    
    always @(posedge clock) begin
        if (reset)
            state <= 4'b0001;
        else
            state <= {state[2:0], state[3]};
    end
endmodule
