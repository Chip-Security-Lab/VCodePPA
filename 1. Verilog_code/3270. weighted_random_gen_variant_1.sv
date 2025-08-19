//SystemVerilog
module weighted_random_gen #(
    parameter WEIGHT_A = 70,  // 70% chance
    parameter WEIGHT_B = 30   // 30% chance
)(
    input wire clock,
    input wire reset,
    output wire select_a, 
    output wire select_b
);

    // LFSR register
    reg [7:0] lfsr_reg;
    // Next LFSR value
    wire [7:0] lfsr_next;
    // Weighted selection combinational outputs
    wire select_a_comb;
    wire select_b_comb;
    // Registered outputs (registers moved backward)
    reg select_a_reg;
    reg select_b_reg;

    // LFSR Next State Computation
    assign lfsr_next = {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};

    // LFSR Register Update
    always @(posedge clock or posedge reset) begin
        if (reset)
            lfsr_reg <= 8'h01;
        else
            lfsr_reg <= lfsr_next;
    end

    // Weighted Selection Combinational Logic (register moved before logic)
    assign select_a_comb = (lfsr_next < WEIGHT_A) ? 1'b1 : 1'b0;
    assign select_b_comb = (lfsr_next < WEIGHT_A) ? 1'b0 : 1'b1;

    // Registered outputs (register moved from output to before combinational logic)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            select_a_reg <= 1'b0;
            select_b_reg <= 1'b0;
        end else begin
            select_a_reg <= select_a_comb;
            select_b_reg <= select_b_comb;
        end
    end

    assign select_a = select_a_reg;
    assign select_b = select_b_reg;

endmodule