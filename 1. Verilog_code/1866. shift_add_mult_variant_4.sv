//SystemVerilog
module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] product
);

    // Stage 1 registers
    reg [WIDTH-1:0] multiplier_stage1;
    reg [WIDTH-1:0] multiplicand_stage1;
    reg [2:0] bit_count_stage1;
    reg [2*WIDTH-1:0] accum_stage1;
    reg valid_stage1;

    // Stage 2 registers
    reg [WIDTH-1:0] multiplier_stage2;
    reg [WIDTH-1:0] multiplicand_stage2;
    reg [2:0] bit_count_stage2;
    reg [2*WIDTH-1:0] accum_stage2;
    reg multiplier_bit_stage2;
    reg [2*WIDTH-1:0] shifted_multiplicand_stage2;
    reg valid_stage2;

    // Stage 3 registers
    reg [WIDTH-1:0] multiplier_stage3;
    reg [2:0] bit_count_stage3;
    reg [2*WIDTH-1:0] accum_stage3;
    reg [2*WIDTH-1:0] add_operand_stage3;
    reg valid_stage3;

    // Stage 4 registers
    reg [WIDTH-1:0] multiplier_stage4;
    reg [2:0] bit_count_stage4;
    reg [2*WIDTH-1:0] accum_stage4;
    reg valid_stage4;

    // Stage 5 registers
    reg [2*WIDTH-1:0] product_stage5;
    reg valid_stage5;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pipeline stages
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_stage3 <= 0;
            valid_stage4 <= 0;
            valid_stage5 <= 0;
            product <= 0;
        end else begin
            // Stage 1: Input and initialization
            if (!valid_stage1) begin
                multiplier_stage1 <= b;
                multiplicand_stage1 <= a;
                bit_count_stage1 <= 0;
                accum_stage1 <= 0;
                valid_stage1 <= 1;
            end

            // Stage 2: Shift and bit extraction
            if (valid_stage1) begin
                multiplier_stage2 <= multiplier_stage1;
                multiplicand_stage2 <= multiplicand_stage1;
                bit_count_stage2 <= bit_count_stage1;
                accum_stage2 <= accum_stage1;
                multiplier_bit_stage2 <= multiplier_stage1[0];
                shifted_multiplicand_stage2 <= multiplicand_stage1 << bit_count_stage1;
                valid_stage2 <= 1;
            end else begin
                valid_stage2 <= 0;
            end

            // Stage 3: Add operand selection
            if (valid_stage2) begin
                multiplier_stage3 <= multiplier_stage2;
                bit_count_stage3 <= bit_count_stage2;
                accum_stage3 <= accum_stage2;
                add_operand_stage3 <= multiplier_bit_stage2 ? shifted_multiplicand_stage2 : 0;
                valid_stage3 <= 1;
            end else begin
                valid_stage3 <= 0;
            end

            // Stage 4: Accumulation
            if (valid_stage3) begin
                multiplier_stage4 <= multiplier_stage3 >> 1;
                bit_count_stage4 <= bit_count_stage3 + 1;
                accum_stage4 <= accum_stage3 + add_operand_stage3;
                valid_stage4 <= 1;
            end else begin
                valid_stage4 <= 0;
            end

            // Stage 5: Output and loop control
            if (valid_stage4) begin
                if (bit_count_stage4 == WIDTH-1) begin
                    product_stage5 <= accum_stage4;
                    valid_stage5 <= 1;
                    valid_stage1 <= 0; // Reset pipeline
                end else begin
                    // Feed back to stage 1
                    multiplier_stage1 <= multiplier_stage4;
                    multiplicand_stage1 <= multiplicand_stage2;
                    bit_count_stage1 <= bit_count_stage4;
                    accum_stage1 <= accum_stage4;
                    valid_stage1 <= 1;
                end
            end else begin
                valid_stage5 <= 0;
            end

            // Output stage
            if (valid_stage5) begin
                product <= product_stage5;
            end
        end
    end
endmodule