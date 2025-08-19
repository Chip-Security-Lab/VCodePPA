//SystemVerilog
module width_adapter #(parameter IN_DW=32, OUT_DW=16) (
    input  [IN_DW-1:0] data_in,
    input              sign_extend,
    output [OUT_DW-1:0] data_out
);
    localparam RATIO = IN_DW / OUT_DW;

    wire [OUT_DW-1:0] subtrahend;
    wire [OUT_DW-1:0] minuend;
    wire [OUT_DW-1:0] diff;
    wire              borrow_out;

    assign minuend    = {OUT_DW{data_in[IN_DW-1]}};
    assign subtrahend = ~data_in[OUT_DW-1:0] + 1'b1;

    wire sign_extend_condition = (|data_in[IN_DW-1:OUT_DW]) && sign_extend;

    wire [OUT_DW-1:0] sign_extended_value;

    borrow_lookahead_subtractor_8bit u_borrow_lookahead_subtractor_8bit (
        .minuend    (minuend),
        .subtrahend (subtrahend),
        .diff       (sign_extended_value),
        .borrow_out (borrow_out)
    );

    assign data_out = sign_extend_condition ? sign_extended_value : data_in[OUT_DW-1:0];

endmodule

module borrow_lookahead_subtractor_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] diff,
    output       borrow_out
);
    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [8:0] borrow;

    assign borrow[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_borrow
            assign generate_borrow[i]  = (~minuend[i]) & subtrahend[i];
            assign propagate_borrow[i] = (~minuend[i]) | subtrahend[i];
            assign borrow[i+1] = generate_borrow[i] | (propagate_borrow[i] & borrow[i]);
            assign diff[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
        end
    endgenerate

    assign borrow_out = borrow[8];
endmodule