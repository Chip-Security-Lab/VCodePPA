//SystemVerilog
module IVMU_DelayArbiter #(parameter DELAY=3) (
    input clk,
    input [3:0] irq,
    output reg [1:0] grant
);

// Counter definition
reg [DELAY-1:0] cnt;

// --- Optimization: Replace (cnt == DELAY-1) comparison using two's complement addition ---

// Constant for two's complement subtraction: -(DELAY-1)
// For unsigned comparison (cnt == DELAY-1), we can check if (cnt - (DELAY-1)) == 0.
// Using two's complement, (cnt - (DELAY-1)) is cnt + (-(DELAY-1)).
// -(DELAY-1) in DELAY bits is computed as ~(DELAY-1) + 1.
// Verilog's unary negation operator '-' computes the two's complement for constants.
parameter [DELAY-1:0] neg_delay_minus_1_tc = -(DELAY-1);

// Perform the addition: cnt + (-(DELAY-1))
// Need DELAY+1 bits to capture the carry-out
wire [DELAY:0] sum_with_carry = cnt + neg_delay_minus_1_tc;

// Extract sum value and carry-out
wire [DELAY-1:0] sum_val = sum_with_carry[DELAY-1:0];
wire cout = sum_with_carry[DELAY];

// The condition (cnt == DELAY-1) is equivalent to (cnt - (DELAY-1) == 0) for unsigned numbers.
// Using two's complement addition, (cnt - (DELAY-1) == 0) is true
// if (cnt + (-(DELAY-1))) results in 0 AND the carry-out is 1 (indicating cnt >= DELAY-1, which is true when equal).
wire cnt_equals_delay_minus_1 = (sum_val == {DELAY{1'b0}}) && (cout == 1'b1);

// --- End Optimization Block ---


always @(posedge clk) begin
    if (|irq) begin
        // Transform cnt assignment from ternary to if-else
        if (cnt_equals_delay_minus_1) begin
            cnt <= {DELAY{1'b0}};
        end else begin
            cnt <= cnt + 1;
        end

        // Transform grant assignment from nested ternary to nested if-else
        // The outer condition corresponds to the first ternary's condition
        if (cnt == {DELAY{1'b0}}) begin
            // The inner conditions correspond to the nested ternaries
            if (irq[0]) begin
                grant <= 2'b00;
            end else if (irq[1]) begin
                grant <= 2'b01;
            end else begin
                grant <= 2'b10;
            end
        end
        // If |irq is true but (cnt == {DELAY{1'b0}}) is false, grant retains its value,
        // which is the implicit behavior for registers not assigned in a branch.
    end
    // If |irq is false, cnt and grant retain their values (implicit latching behavior for registers)
end

endmodule