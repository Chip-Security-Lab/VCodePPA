//SystemVerilog

module shift_mux_based #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] shift_amt,
    output [WIDTH-1:0] data_out
);

    wire [WIDTH-1:0] shift_result;
    wire [WIDTH-1:0] shift_in [0:$clog2(WIDTH)];
    assign shift_in[0] = data_in;

    genvar i;
    generate
        for (i = 0; i < $clog2(WIDTH); i = i + 1) begin : gen_barrel_shift
            wire [WIDTH-1:0] shifted;
            assign shifted = shift_in[i] << (1 << i);
            assign shift_in[i+1] = shift_amt[i] ? shifted : shift_in[i];
        end
    endgenerate

    assign shift_result = shift_in[$clog2(WIDTH)];
    assign data_out = shift_result;

endmodule

// 8-bit Borrow Lookahead Subtractor using Carry Lookahead-style Borrow Logic
module borrow_lookahead_subtractor_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference,
    output       borrow_out
);
    wire [7:0] borrow_generate;
    wire [7:0] borrow_propagate;
    wire [7:0] borrow_internal;

    // Borrow Generate and Propagate
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_borrow_gp
            assign borrow_generate[i]  = ~minuend[i] & subtrahend[i];
            assign borrow_propagate[i] = ~minuend[i] | subtrahend[i];
        end
    endgenerate

    // Borrow Lookahead Logic
    wire b1, b2, b3, b4, b5, b6, b7;

    assign borrow_internal[0] = borrow_generate[0];
    assign b1 = borrow_generate[1] | (borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[1] = b1;
    assign b2 = borrow_generate[2] | (borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[2] = b2;
    assign b3 = borrow_generate[3] | (borrow_propagate[3] & borrow_generate[2]) | (borrow_propagate[3] & borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[3] & borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[3] = b3;
    assign b4 = borrow_generate[4] | (borrow_propagate[4] & borrow_generate[3]) | (borrow_propagate[4] & borrow_propagate[3] & borrow_generate[2]) | (borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[4] = b4;
    assign b5 = borrow_generate[5] | (borrow_propagate[5] & borrow_generate[4]) | (borrow_propagate[5] & borrow_propagate[4] & borrow_generate[3]) | (borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_generate[2]) | (borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[5] = b5;
    assign b6 = borrow_generate[6] | (borrow_propagate[6] & borrow_generate[5]) | (borrow_propagate[6] & borrow_propagate[5] & borrow_generate[4]) | (borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_generate[3]) | (borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_generate[2]) | (borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[6] = b6;
    assign b7 = borrow_generate[7] | (borrow_propagate[7] & borrow_generate[6]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_generate[5]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_propagate[5] & borrow_generate[4]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_generate[3]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_generate[2]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_generate[1]) | (borrow_propagate[7] & borrow_propagate[6] & borrow_propagate[5] & borrow_propagate[4] & borrow_propagate[3] & borrow_propagate[2] & borrow_propagate[1] & borrow_generate[0]);
    assign borrow_internal[7] = b7;

    // Difference Calculation
    assign difference[0] = minuend[0] ^ subtrahend[0];
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow_internal[0];
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow_internal[1];
    assign difference[3] = minuend[3] ^ subtrahend[3] ^ borrow_internal[2];
    assign difference[4] = minuend[4] ^ subtrahend[4] ^ borrow_internal[3];
    assign difference[5] = minuend[5] ^ subtrahend[5] ^ borrow_internal[4];
    assign difference[6] = minuend[6] ^ subtrahend[6] ^ borrow_internal[5];
    assign difference[7] = minuend[7] ^ subtrahend[7] ^ borrow_internal[6];

    assign borrow_out = borrow_internal[7];

endmodule