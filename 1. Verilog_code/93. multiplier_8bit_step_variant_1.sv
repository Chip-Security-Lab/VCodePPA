//SystemVerilog
module multiplier_8bit_step (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

    // Internal signals for partial products
    reg [15:0] partial_products [7:0];
    reg [15:0] sum_stage1 [3:0];
    reg [15:0] sum_stage2 [1:0];
    
    // Generate partial products for each bit of input a
    always @(*) begin
        for (integer i = 0; i < 8; i = i + 1) begin
            partial_products[i] = 16'b0;
        end
    end

    // Generate partial products for each bit of input b
    always @(*) begin
        for (integer i = 0; i < 8; i = i + 1) begin
            for (integer j = 0; j < 8; j = j + 1) begin
                if (a[i] & b[j]) begin
                    partial_products[i][i+j] = 1'b1;
                end
            end
        end
    end

    // First stage of addition - process pairs of partial products
    always @(*) begin
        for (integer i = 0; i < 4; i = i + 1) begin
            sum_stage1[i] = partial_products[2*i] ^ partial_products[2*i+1];
        end
    end

    // Second stage of addition - process pairs of first stage results
    always @(*) begin
        for (integer i = 0; i < 2; i = i + 1) begin
            sum_stage2[i] = sum_stage1[2*i] ^ sum_stage1[2*i+1];
        end
    end

    // Final addition - combine second stage results
    always @(*) begin
        product = sum_stage2[0] ^ sum_stage2[1];
    end

endmodule