module weighted_random_gen #(
    parameter WEIGHT_A = 70,  // 70% chance
    parameter WEIGHT_B = 30   // 30% chance
)(
    input wire clock,
    input wire reset,
    output wire select_a, 
    output wire select_b
);
    reg [7:0] lfsr;
    wire [7:0] next_lfsr;
    
    assign next_lfsr = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    
    always @(posedge clock) begin
        if (reset)
            lfsr <= 8'h01;
        else
            lfsr <= next_lfsr;
    end
    
    assign select_a = (lfsr < WEIGHT_A) ? 1'b1 : 1'b0;
    assign select_b = !select_a;
endmodule