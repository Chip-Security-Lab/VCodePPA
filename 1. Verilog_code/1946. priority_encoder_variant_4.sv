//SystemVerilog
module priority_encoder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] request,
    output reg [$clog2(WIDTH)-1:0] grant_id,
    output reg valid
);
    wire [WIDTH-1:0] one_hot;
    wire [$clog2(WIDTH)-1:0] encoded_id;
    wire is_valid;

    // Borrow Subtractor for 8-bit
    wire [7:0] minuend, subtrahend;
    wire [7:0] difference;
    wire borrow_final;

    assign minuend = request;
    assign subtrahend = 8'b0;

    borrow_subtractor_8bit u_borrow_subtractor (
        .minuend(minuend),
        .subtrahend(subtrahend),
        .difference(difference),
        .borrow_out(borrow_final)
    );

    // One-hot encoding: highest priority (leftmost '1')
    assign one_hot = difference & (~({difference[6:0], 1'b0}));

    // Encode the one-hot to binary index
    function [2:0] one_hot_to_bin;
        input [7:0] val;
        begin
            casex(val)
                8'b1xxxxxxx: one_hot_to_bin = 3'd7;
                8'b01xxxxxx: one_hot_to_bin = 3'd6;
                8'b001xxxxx: one_hot_to_bin = 3'd5;
                8'b0001xxxx: one_hot_to_bin = 3'd4;
                8'b00001xxx: one_hot_to_bin = 3'd3;
                8'b000001xx: one_hot_to_bin = 3'd2;
                8'b0000001x: one_hot_to_bin = 3'd1;
                8'b00000001: one_hot_to_bin = 3'd0;
                default: one_hot_to_bin = 3'd0;
            endcase
        end
    endfunction

    assign encoded_id = one_hot_to_bin(one_hot);

    assign is_valid = |request;

    always @(*) begin
        grant_id = encoded_id;
        valid = is_valid;
    end

endmodule

// 8-bit Borrow Subtractor (bitwise borrow chain)
module borrow_subtractor_8bit (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference,
    output wire       borrow_out
);
    wire [8:0] borrow_chain;

    assign borrow_chain[0] = 1'b0;

    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : borrow_chain_gen
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = (~minuend[i] & subtrahend[i]) | ((~minuend[i] | subtrahend[i]) & borrow_chain[i]);
        end
    endgenerate

    assign borrow_out = borrow_chain[8];
endmodule