//SystemVerilog
module AlwaysNor(
    input  [7:0] a,
    input  [7:0] b,
    output reg [15:0] y
);

    // Internal signals for Baugh-Wooley multiplication
    reg [7:0] a_reg, b_reg;
    reg [15:0] partial_products [7:0];
    reg [15:0] sum_stage1 [3:0];
    reg [15:0] sum_stage2 [1:0];
    reg [15:0] final_sum;

    integer i;

    // Register inputs to improve timing
    always @(*) begin
        a_reg = a;
        b_reg = b;

        // Compute partial products with Baugh-Wooley sign handling
        for (i = 0; i < 8; i = i + 1) begin
            if (i < 7) begin
                partial_products[i] = {8'b0, (a_reg & {8{b_reg[i]}})} << i;
            end else begin
                // For the MSB of b (sign bit), invert a except for LSB
                partial_products[7] = {8'b0, (~a_reg & 8'hFF)} << 7;
            end
        end

        // Apply Baugh-Wooley corrections for sign bits
        // Add b's sign bit to the partial sums
        partial_products[0] = partial_products[0] | ({8'b0, {8{a_reg[7]}}});

        // Add a's sign bit to the partial sums
        for (i = 0; i < 8; i = i + 1) begin
            if (i < 7)
                partial_products[i] = partial_products[i] | (({8'b0, {8{b_reg[7]}}}) << i);
        end

        // Add 1 at position 15 for two's complement
        partial_products[7][15] = partial_products[7][15] + 1'b1;

        // Sum partial products (multi-stage adder tree for better PPA)
        sum_stage1[0] = partial_products[0] + partial_products[1];
        sum_stage1[1] = partial_products[2] + partial_products[3];
        sum_stage1[2] = partial_products[4] + partial_products[5];
        sum_stage1[3] = partial_products[6] + partial_products[7];

        sum_stage2[0] = sum_stage1[0] + sum_stage1[1];
        sum_stage2[1] = sum_stage1[2] + sum_stage1[3];

        final_sum = sum_stage2[0] + sum_stage2[1];

        y = final_sum;
    end

endmodule