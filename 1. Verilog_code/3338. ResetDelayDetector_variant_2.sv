//SystemVerilog
module ResetDelayDetector #(
    parameter DELAY = 4
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);
    reg [DELAY-1:0] shift_reg;
    wire all_ones;
    wire [7:0] a_sub_b;
    wire borrow_out;

    assign all_ones = (shift_reg == {DELAY{1'b1}});
    assign reset_detected = shift_reg[DELAY-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {DELAY{1'b1}};
        else if (!all_ones)
            shift_reg <= {shift_reg[DELAY-2:0], 1'b0};
    end
endmodule

// 8-bit Parallel Prefix Subtractor (Kogge-Stone style)
module ParallelPrefixSubtractor8 (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    input  wire       borrow_in,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] g; // generate: ~a & b
    wire [7:0] p; // propagate: ~(a ^ b)
    wire [7:0] b_int;

    assign g = (~minuend) & subtrahend;
    assign p = ~(minuend ^ subtrahend);

    // Stage 0
    assign b_int[0] = g[0] | (p[0] & borrow_in);
    assign b_int[1] = g[1] | (p[1] & b_int[0]);
    assign b_int[2] = g[2] | (p[2] & b_int[1]);
    assign b_int[3] = g[3] | (p[3] & b_int[2]);
    assign b_int[4] = g[4] | (p[4] & b_int[3]);
    assign b_int[5] = g[5] | (p[5] & b_int[4]);
    assign b_int[6] = g[6] | (p[6] & b_int[5]);
    assign b_int[7] = g[7] | (p[7] & b_int[6]);
    assign borrow_out = b_int[7];

    assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow_in;
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ b_int[0];
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ b_int[1];
    assign difference[3] = minuend[3] ^ subtrahend[3] ^ b_int[2];
    assign difference[4] = minuend[4] ^ subtrahend[4] ^ b_int[3];
    assign difference[5] = minuend[5] ^ subtrahend[5] ^ b_int[4];
    assign difference[6] = minuend[6] ^ subtrahend[6] ^ b_int[5];
    assign difference[7] = minuend[7] ^ subtrahend[7] ^ b_int[6];
endmodule