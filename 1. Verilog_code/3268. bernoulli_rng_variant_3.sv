//SystemVerilog
module bernoulli_rng #(
    parameter THRESHOLD = 128 // Probability = THRESHOLD/256
)(
    input  wire        clk,
    input  wire        rst,
    output wire        random_bit
);

    // LFSR state register
    reg  [7:0] lfsr_reg;
    wire [7:0] lfsr_next;

    // First-level buffer for lfsr_reg
    reg  [7:0] lfsr_buf_stage1;
    // Second-level buffer for lfsr_reg
    reg  [7:0] lfsr_buf_stage2;

    // Function: Compute next LFSR value
    assign lfsr_next = {lfsr_reg[6:0], lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};

    // Sequential logic: LFSR state update
    always @(posedge clk) begin
        if (rst)
            lfsr_reg <= 8'h1;
        else
            lfsr_reg <= lfsr_next;
    end

    // Buffering lfsr_reg to reduce fanout and balance load
    always @(posedge clk) begin
        if (rst) begin
            lfsr_buf_stage1 <= 8'h1;
            lfsr_buf_stage2 <= 8'h1;
        end else begin
            lfsr_buf_stage1 <= lfsr_reg;
            lfsr_buf_stage2 <= lfsr_buf_stage1;
        end
    end

    // Use the final buffered lfsr value for comparison to minimize lfsr_reg fanout
    assign random_bit = (lfsr_buf_stage2 < THRESHOLD) ? 1'b1 : 1'b0;

endmodule