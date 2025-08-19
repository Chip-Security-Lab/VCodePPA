//SystemVerilog
module shift_cycl_right_comb #(parameter WIDTH=8) (
    input  wire [WIDTH-1:0] din,
    input  wire [2:0] shift_amt,
    output wire [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] stage0, stage1, stage2;

    // Stage 0: shift by 1 if shift_amt[0] is set
    genvar i0;
    generate
        for (i0 = 0; i0 < WIDTH; i0 = i0 + 1) begin : gen_stage0
            assign stage0[i0] = shift_amt[0] ? din[(i0+1)%WIDTH] : din[i0];
        end
    endgenerate

    // Stage 1: shift by 2 if shift_amt[1] is set
    genvar i1;
    generate
        for (i1 = 0; i1 < WIDTH; i1 = i1 + 1) begin : gen_stage1
            assign stage1[i1] = shift_amt[1] ? stage0[(i1+2)%WIDTH] : stage0[i1];
        end
    endgenerate

    // Stage 2: shift by 4 if shift_amt[2] is set
    genvar i2;
    generate
        for (i2 = 0; i2 < WIDTH; i2 = i2 + 1) begin : gen_stage2
            assign stage2[i2] = shift_amt[2] ? stage1[(i2+4)%WIDTH] : stage1[i2];
        end
    endgenerate

    assign dout = stage2;

endmodule