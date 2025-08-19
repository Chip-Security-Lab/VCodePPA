//SystemVerilog
module rng_lfsr_12(
    input           clk,
    input           en,
    output [3:0]    rand_out
);
    reg [3:0] state_reg = 4'b1010;
    reg [3:0] state_buf1;
    reg [3:0] state_buf2;
    wire feedback_bit;

    // LFSR logic
    assign feedback_bit = state_reg[3] ^ state_reg[2];

    always @(posedge clk) begin
        if (en) begin
            state_reg <= {state_reg[2:0], feedback_bit};
        end
    end

    // Buffer stage 1 for state_reg
    always @(posedge clk) begin
        state_buf1 <= state_reg;
    end

    // Buffer stage 2 for state_buf1
    always @(posedge clk) begin
        state_buf2 <= state_buf1;
    end

    // Output from final buffer stage
    assign rand_out = state_buf2;
endmodule