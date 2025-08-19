//SystemVerilog
module weighted_random_gen #(
    parameter WEIGHT_A = 70,  // 70% chance
    parameter WEIGHT_B = 30   // 30% chance
)(
    input  wire clock,
    input  wire reset,
    output reg  select_a,
    output reg  select_b
);
    reg [7:0] lfsr;
    wire [7:0] next_lfsr;
    wire is_a_range;

    assign next_lfsr = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

    // Efficient range check: select_a is high only if lfsr is in [0, WEIGHT_A-1]
    assign is_a_range = (lfsr < WEIGHT_A);

    always @(posedge clock) begin
        if (reset) begin
            lfsr     <= 8'h01;
            select_a <= 1'b0;
            select_b <= 1'b0;
        end else begin
            lfsr     <= next_lfsr;
            select_a <= is_a_range;
            select_b <= ~is_a_range;
        end
    end
endmodule