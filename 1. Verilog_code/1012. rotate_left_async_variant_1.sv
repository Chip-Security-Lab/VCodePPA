//SystemVerilog
module rotate_left_async #(parameter WIDTH=8) (
    input  [WIDTH-1:0] din,
    input  [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] dout
);
    wire [WIDTH-1:0] stage0;
    wire [WIDTH-1:0] stage1;
    wire [WIDTH-1:0] stage2;
    wire [WIDTH-1:0] stage3;
    wire [WIDTH-1:0] stage4;
    wire [WIDTH-1:0] stage5;

    localparam integer S = $clog2(WIDTH);

    // Stage 0: initial assignment
    assign stage0 = din;

    // Stage 1: shift by 1
    generate
        if (WIDTH >= 2) begin : gen_stage1
            genvar i1;
            for (i1 = 0; i1 < WIDTH; i1 = i1 + 1) begin : bit1
                assign stage1[i1] = shift[0] ? stage0[(i1-1+WIDTH)%WIDTH] : stage0[i1];
            end
        end else begin : gen_stage1_bypass
            assign stage1 = stage0;
        end
    endgenerate

    // Stage 2: shift by 2
    generate
        if (WIDTH >= 4) begin : gen_stage2
            genvar i2;
            for (i2 = 0; i2 < WIDTH; i2 = i2 + 1) begin : bit2
                assign stage2[i2] = shift[1] ? stage1[(i2-2+WIDTH)%WIDTH] : stage1[i2];
            end
        end else begin : gen_stage2_bypass
            assign stage2 = stage1;
        end
    endgenerate

    // Stage 3: shift by 4
    generate
        if (WIDTH >= 8) begin : gen_stage3
            genvar i3;
            for (i3 = 0; i3 < WIDTH; i3 = i3 + 1) begin : bit3
                assign stage3[i3] = shift[2] ? stage2[(i3-4+WIDTH)%WIDTH] : stage2[i3];
            end
        end else begin : gen_stage3_bypass
            assign stage3 = stage2;
        end
    endgenerate

    // Stage 4: shift by 8
    generate
        if (WIDTH >= 16) begin : gen_stage4
            genvar i4;
            for (i4 = 0; i4 < WIDTH; i4 = i4 + 1) begin : bit4
                assign stage4[i4] = shift[3] ? stage3[(i4-8+WIDTH)%WIDTH] : stage3[i4];
            end
        end else begin : gen_stage4_bypass
            assign stage4 = stage3;
        end
    endgenerate

    // Stage 5: shift by 16
    generate
        if (WIDTH >= 32) begin : gen_stage5
            genvar i5;
            for (i5 = 0; i5 < WIDTH; i5 = i5 + 1) begin : bit5
                assign stage5[i5] = shift[4] ? stage4[(i5-16+WIDTH)%WIDTH] : stage4[i5];
            end
        end else begin : gen_stage5_bypass
            assign stage5 = stage4;
        end
    endgenerate

    // Output selection based on WIDTH
    generate
        if (WIDTH >= 32) begin : gen_out_32
            assign dout = stage5;
        end else if (WIDTH >= 16) begin : gen_out_16
            assign dout = stage4;
        end else if (WIDTH >= 8) begin : gen_out_8
            assign dout = stage3;
        end else if (WIDTH >= 4) begin : gen_out_4
            assign dout = stage2;
        end else if (WIDTH >= 2) begin : gen_out_2
            assign dout = stage1;
        end else begin : gen_out_1
            assign dout = stage0;
        end
    endgenerate

endmodule