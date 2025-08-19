//SystemVerilog
module fixed2float #(
    parameter INT_BITS = 8,
    parameter FRACT_BITS = 8,
    parameter EXP_BITS = 8,
    parameter MANT_BITS = 23
)(
    input  wire signed [INT_BITS+FRACT_BITS-1:0] fixed_in,
    output reg  [EXP_BITS+MANT_BITS:0] float_out
);

    // Pipeline stage 1: Extract sign and absolute value
    reg                        sign_stage1;
    reg  [INT_BITS+FRACT_BITS-1:0] abs_val_stage1;

    always @(*) begin
        sign_stage1      = fixed_in[INT_BITS+FRACT_BITS-1];
        abs_val_stage1   = fixed_in[INT_BITS+FRACT_BITS-1] ? kogge_stone_adder_8(~fixed_in[INT_BITS+FRACT_BITS-1:0], 8'b1) : fixed_in[INT_BITS+FRACT_BITS-1:0];
    end

    // Pipeline stage 2: Leading zero detection (placeholder, should be replaced in production)
    reg  [$clog2(INT_BITS+FRACT_BITS)-1:0] leading_zeros_stage2;
    reg  [$clog2(INT_BITS+FRACT_BITS)-1:0] shift_amt_stage2;
    reg  [INT_BITS+FRACT_BITS-1:0]         abs_val_stage2;
    reg                                    sign_stage2;

    always @(*) begin
        sign_stage2        = sign_stage1;
        abs_val_stage2     = abs_val_stage1;
        // Simple leading zero detector (for demonstration; replace for production)
        leading_zeros_stage2 = abs_val_stage1[INT_BITS+FRACT_BITS-1] ? 0 : 1;
        shift_amt_stage2     = INT_BITS + FRACT_BITS - 1 - leading_zeros_stage2;
    end

    // Pipeline stage 3: Exponent and mantissa calculation
    reg [EXP_BITS-1:0]  exponent_stage3;
    reg [MANT_BITS-1:0] mantissa_stage3;
    reg                 sign_stage3;

    wire [INT_BITS+FRACT_BITS-1:0] mantissa_shifted;
    assign mantissa_shifted = abs_val_stage2 << (MANT_BITS - shift_amt_stage2);

    always @(*) begin
        sign_stage3      = sign_stage2;
        exponent_stage3  = kogge_stone_adder_8(127, kogge_stone_adder_8(shift_amt_stage2, ~FRACT_BITS + 1));
        mantissa_stage3  = mantissa_shifted;
    end

    // Pipeline stage 4: Output assembly
    always @(*) begin
        float_out[EXP_BITS+MANT_BITS]           = sign_stage3;
        float_out[EXP_BITS+MANT_BITS-1:MANT_BITS] = exponent_stage3;
        float_out[MANT_BITS-1:0]                = mantissa_stage3;
    end

    // 8-bit Kogge-Stone Adder function
    function [7:0] kogge_stone_adder_8;
        input [7:0] a;
        input [7:0] b;
        reg   [7:0] p [0:3];
        reg   [7:0] g [0:3];
        reg   [7:0] c;
        integer i;
        begin
            // Stage 0: Initial propagate and generate
            p[0] = a ^ b;
            g[0] = a & b;

            // Stage 1
            p[1][0] = p[0][0];
            g[1][0] = g[0][0];
            for (i = 1; i < 8; i = i + 1) begin
                p[1][i] = p[0][i] & p[0][i-1];
                g[1][i] = g[0][i] | (p[0][i] & g[0][i-1]);
            end

            // Stage 2
            p[2][1:0] = p[1][1:0];
            g[2][1:0] = g[1][1:0];
            for (i = 2; i < 8; i = i + 1) begin
                p[2][i] = p[1][i] & p[1][i-2];
                g[2][i] = g[1][i] | (p[1][i] & g[1][i-2]);
            end

            // Stage 3
            p[3][3:0] = p[2][3:0];
            g[3][3:0] = g[2][3:0];
            for (i = 4; i < 8; i = i + 1) begin
                p[3][i] = p[2][i] & p[2][i-4];
                g[3][i] = g[2][i] | (p[2][i] & g[2][i-4]);
            end

            // Carry generation
            c[0] = 1'b0;
            c[1] = g[0][0];
            c[2] = g[1][1];
            c[3] = g[2][2];
            c[4] = g[3][3];
            c[5] = g[3][4];
            c[6] = g[3][5];
            c[7] = g[3][6];

            // Final sum
            kogge_stone_adder_8[0] = p[0][0] ^ c[0];
            kogge_stone_adder_8[1] = p[0][1] ^ c[1];
            kogge_stone_adder_8[2] = p[0][2] ^ c[2];
            kogge_stone_adder_8[3] = p[0][3] ^ c[3];
            kogge_stone_adder_8[4] = p[0][4] ^ c[4];
            kogge_stone_adder_8[5] = p[0][5] ^ c[5];
            kogge_stone_adder_8[6] = p[0][6] ^ c[6];
            kogge_stone_adder_8[7] = p[0][7] ^ c[7];
        end
    endfunction

endmodule