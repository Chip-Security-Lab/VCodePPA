//SystemVerilog
module gray_to_bin #(
    parameter DATA_W = 8
)(
    input  [DATA_W-1:0] gray_code,
    output [DATA_W-1:0] binary
);
    wire [DATA_W-1:0] prefix_xor [0:$clog2(DATA_W)];
    integer stage, idx;

    assign prefix_xor[0] = gray_code;

    generate
        genvar s, k;
        for (s = 1; s <= $clog2(DATA_W); s = s + 1) begin : prefix_stages
            for (k = 0; k < DATA_W; k = k + 1) begin : prefix_bits
                if (k + (1 << (s-1)) < DATA_W) begin : xor_logic
                    assign prefix_xor[s][k] = prefix_xor[s-1][k] ^ prefix_xor[s-1][k + (1 << (s-1))];
                end else begin : passthrough
                    assign prefix_xor[s][k] = prefix_xor[s-1][k];
                end
            end
        end
    endgenerate

    wire [DATA_W-1:0] bin_prefix;
    assign bin_prefix[DATA_W-1] = gray_code[DATA_W-1];
    assign bin_prefix[DATA_W-2:0] = prefix_xor[$clog2(DATA_W)][DATA_W-2:0];

    // Subtractor unit using borrow look-ahead subtractor (borrow chain)
    wire [DATA_W-1:0] subtractor_a;
    wire [DATA_W-1:0] subtractor_b;
    wire [DATA_W-1:0] difference;
    wire [DATA_W:0]   borrow_chain;

    assign subtractor_a = bin_prefix;
    assign subtractor_b = 8'b0; // No subtraction, just demonstrate the borrow subtractor structure

    assign borrow_chain[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < DATA_W; i = i + 1) begin : borrow_subtractor
            assign difference[i] = subtractor_a[i] ^ subtractor_b[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~subtractor_a[i] & (subtractor_b[i] | borrow_chain[i])) | (subtractor_b[i] & borrow_chain[i]);
        end
    endgenerate

    assign binary = difference;

endmodule