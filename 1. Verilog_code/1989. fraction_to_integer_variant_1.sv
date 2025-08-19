//SystemVerilog
module fraction_to_integer #(parameter INT_WIDTH=8, FRAC_WIDTH=8)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_in,
    output reg  [INT_WIDTH-1:0]          int_out
);

    // Stage 1: Extract integer and rounding bit from input
    reg [INT_WIDTH-1:0]     stage1_integer_part;
    reg                     stage1_round_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_integer_part <= {INT_WIDTH{1'b0}};
            stage1_round_bit    <= 1'b0;
        end else begin
            stage1_integer_part <= frac_in[INT_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
            stage1_round_bit    <= frac_in[FRAC_WIDTH-1];
        end
    end

    // Stage 2: Generate rounding extension
    reg [INT_WIDTH-1:0]     stage2_round_bit_ext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_round_bit_ext <= {INT_WIDTH{1'b0}};
        end else begin
            stage2_round_bit_ext <= { {(INT_WIDTH-1){1'b0}}, stage1_round_bit };
        end
    end

    // Stage 3: Add integer part with rounding extension
    reg [INT_WIDTH-1:0]     stage3_sum_with_round;
    reg                     stage3_carry_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_sum_with_round <= {INT_WIDTH{1'b0}};
            stage3_carry_out      <= 1'b0;
        end else begin
            {stage3_carry_out, stage3_sum_with_round} <= stage1_integer_part + stage2_round_bit_ext;
        end
    end

    // Stage 4: Output result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {INT_WIDTH{1'b0}};
        end else begin
            int_out <= stage3_sum_with_round;
        end
    end

endmodule