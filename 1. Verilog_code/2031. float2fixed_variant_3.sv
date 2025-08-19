//SystemVerilog
module float2fixed #(parameter INT=4, FRAC=4) (
    input wire clk,
    input wire valid_in,
    input wire [31:0] float_in,
    output reg [INT+FRAC-1:0] fixed_out
);
    localparam TOTAL_WIDTH = INT + FRAC;

    // Pipeline stage 1 registers
    reg [31:0] float_in_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers
    reg [31:0] masked_float_stage2;
    reg valid_stage2;

    // Pipeline stage 3 registers
    reg [TOTAL_WIDTH-1:0] extracted_bits_stage3;
    reg valid_stage3;

    // Stage 1: Register input
    always @(posedge clk) begin
        float_in_stage1 <= float_in;
        valid_stage1 <= valid_in;
    end

    // Stage 2: Mask input and register
    always @(posedge clk) begin
        masked_float_stage2 <= float_in_stage1 & {32{(TOTAL_WIDTH != 0)}};
        valid_stage2 <= valid_stage1;
    end

    // Stage 3: Extract bits and register
    always @(posedge clk) begin
        extracted_bits_stage3 <= masked_float_stage2[TOTAL_WIDTH-1:0];
        valid_stage3 <= valid_stage2;
    end

    // Stage 4: Output register
    always @(posedge clk) begin
        if (valid_stage3)
            fixed_out <= extracted_bits_stage3;
    end

endmodule