//SystemVerilog
module conditional_sum_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    input  wire       borrow_in,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [7:0] borrow_chain;
    wire [7:0] diff_result;

    // Intermediate signals for borrow logic
    wire [7:0] minuend_inv;
    wire [7:0] minuend_inv_and_subtrahend;
    wire [7:0] minuend_inv_or_subtrahend;
    wire [7:0] prev_borrow;

    assign minuend_inv = ~minuend;
    assign prev_borrow[0] = borrow_in;
    assign prev_borrow[1] = borrow_chain[0];
    assign prev_borrow[2] = borrow_chain[1];
    assign prev_borrow[3] = borrow_chain[2];
    assign prev_borrow[4] = borrow_chain[3];
    assign prev_borrow[5] = borrow_chain[4];
    assign prev_borrow[6] = borrow_chain[5];
    assign prev_borrow[7] = borrow_chain[6];

    genvar idx;
    generate
        for (idx = 0; idx < 8; idx = idx + 1) begin : diff_borrow_chain
            assign minuend_inv_and_subtrahend[idx] = minuend_inv[idx] & subtrahend[idx];
            assign minuend_inv_or_subtrahend[idx]  = minuend_inv[idx] | subtrahend[idx];

            // Calculate difference
            assign diff_result[idx] = minuend[idx] ^ subtrahend[idx] ^ prev_borrow[idx];

            // Calculate borrow
            wire cond1, cond2;
            assign cond1 = minuend_inv_and_subtrahend[idx];
            assign cond2 = minuend_inv_or_subtrahend[idx] & prev_borrow[idx];
            assign borrow_chain[idx] = cond1 | cond2;
        end
    endgenerate

    assign difference = diff_result;
    assign borrow_out = borrow_chain[7];

endmodule