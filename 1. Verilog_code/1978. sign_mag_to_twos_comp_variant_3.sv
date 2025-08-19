//SystemVerilog
module sign_mag_to_twos_comp #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] sign_mag_in,
    output reg  [WIDTH-1:0] twos_comp_out
);

    // Pipeline stage 1: Extract sign and magnitude, generate inversion
    reg                  sign_stage1;
    reg  [WIDTH-2:0]     mag_stage1;
    reg  [WIDTH-2:0]     mag_inv_stage1;

    // Pipeline stage 2: Compute propagate and generate signals
    reg                  sign_stage2;
    reg  [WIDTH-2:0]     pb_stage2;
    reg  [WIDTH-2:0]     gb_stage2;
    reg  [WIDTH-2:0]     mag_inv_stage2;

    // Pipeline stage 3: Compute borrow chain
    reg                  sign_stage3;
    reg  [WIDTH-2:0]     borrow_stage3;
    reg  [WIDTH-2:0]     mag_inv_stage3;
    reg  [WIDTH-2:0]     pb_stage3;

    // Pipeline stage 4: Compute difference bits
    reg                  sign_stage4;
    reg  [WIDTH-2:0]     diff_stage4;

    integer j;

    // Stage 1: Extract sign, magnitude, and invert magnitude
    always @* begin
        sign_stage1    = sign_mag_in[WIDTH-1];
        mag_stage1     = sign_mag_in[WIDTH-2:0];
        mag_inv_stage1 = ~sign_mag_in[WIDTH-2:0];
    end

    // Stage 2: Propagate and generate signals
    always @* begin
        sign_stage2     = sign_stage1;
        mag_inv_stage2  = mag_inv_stage1;
        for (j = 0; j < WIDTH-1; j = j + 1) begin
            pb_stage2[j] = sign_stage1 ^ mag_inv_stage1[j];
            gb_stage2[j] = (~sign_stage1) & mag_inv_stage1[j];
        end
    end

    // Stage 3: Borrow chain calculation
    always @* begin
        sign_stage3    = sign_stage2;
        mag_inv_stage3 = mag_inv_stage2;
        pb_stage3      = pb_stage2;
        borrow_stage3[0] = gb_stage2[0];
        for (j = 1; j < WIDTH-1; j = j + 1) begin
            borrow_stage3[j] = gb_stage2[j] | (pb_stage2[j] & borrow_stage3[j-1]);
        end
    end

    // Stage 4: Difference computation
    always @* begin
        sign_stage4 = sign_stage3;
        diff_stage4[0] = sign_stage3 ^ mag_inv_stage3[0];
        for (j = 1; j < WIDTH-1; j = j + 1) begin
            diff_stage4[j] = (sign_stage3 ^ mag_inv_stage3[j]) ^ borrow_stage3[j-1];
        end
    end

    // Output assignment with pipeline alignment
    always @* begin
        if (sign_stage4) begin
            twos_comp_out = {1'b1, diff_stage4};
        end else begin
            twos_comp_out = {sign_stage4, mag_stage1};
        end
    end

endmodule