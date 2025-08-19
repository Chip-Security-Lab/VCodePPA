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
    // Primary LFSR register
    reg [7:0] lfsr_reg;

    // First stage LFSR buffer
    reg [7:0] lfsr_buf1;

    // Second stage LFSR buffer (for further fanout reduction if needed)
    reg [7:0] lfsr_buf2;

    wire [7:0] next_lfsr;
    reg select_a_next;
    reg select_b_next;

    // LFSR logic
    assign next_lfsr = {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};

    // LFSR buffering stages for load balancing and fanout reduction
    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg  <= 8'h01;
            lfsr_buf1 <= 8'h01;
            lfsr_buf2 <= 8'h01;
        end else begin
            lfsr_reg  <= next_lfsr;
            lfsr_buf1 <= lfsr_reg;
            lfsr_buf2 <= lfsr_buf1;
        end
    end

    // Use lfsr_buf2 for all downstream logic to reduce fanout from lfsr_reg
    always @(*) begin
        select_a_next = (lfsr_buf2 < WEIGHT_A);
        select_b_next = (lfsr_buf2 >= WEIGHT_A) && (lfsr_buf2 < (WEIGHT_A + WEIGHT_B));
    end

    // Output registers
    always @(posedge clock) begin
        if (reset) begin
            select_a <= 1'b0;
            select_b <= 1'b0;
        end else begin
            select_a <= select_a_next;
            select_b <= select_b_next;
        end
    end
endmodule