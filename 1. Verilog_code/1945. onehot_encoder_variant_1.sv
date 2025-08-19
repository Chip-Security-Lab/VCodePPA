//SystemVerilog
module onehot_encoder #(
    parameter IN_WIDTH = 4
)(
    input wire [IN_WIDTH-1:0] binary_in,
    input wire valid_in,
    output reg [(1<<IN_WIDTH)-1:0] onehot_out,
    output reg error
);
    wire [IN_WIDTH-1:0] max_val;
    wire [IN_WIDTH-1:0] borrow_dummy;
    wire subtraction_error;

    assign max_val = {IN_WIDTH{1'b1}};

    // 4-bit Parallel Borrow Lookahead Subtractor
    borrow_lookahead_subtractor_4bit u_borrow_lookahead_subtractor_4bit (
        .minuend(max_val),
        .subtrahend(binary_in),
        .borrow_in(1'b0),
        .difference(),
        .borrow_out(borrow_dummy[IN_WIDTH-1])
    );

    assign subtraction_error = borrow_dummy[IN_WIDTH-1];

    always @(*) begin : onehot_encoder_logic
        onehot_out = {((1<<IN_WIDTH)){1'b0}};
        error = 1'b0;
        case ({valid_in, subtraction_error})
            2'b10: begin
                onehot_out = 1'b1 << binary_in;
                error = 1'b0;
            end
            2'b11: begin
                onehot_out = {((1<<IN_WIDTH)){1'b0}};
                error = 1'b1;
            end
            default: begin
                onehot_out = {((1<<IN_WIDTH)){1'b0}};
                error = 1'b0;
            end
        endcase
    end
endmodule

// 4-bit Borrow Lookahead Subtractor Module
module borrow_lookahead_subtractor_4bit (
    input  wire [3:0] minuend,
    input  wire [3:0] subtrahend,
    input  wire       borrow_in,
    output wire [3:0] difference,
    output wire       borrow_out
);
    wire [3:0] generate_borrow;
    wire [3:0] propagate_borrow;
    wire [3:0] borrow_chain;

    assign generate_borrow[0] = (~minuend[0]) & subtrahend[0];
    assign propagate_borrow[0] = ~(minuend[0] ^ subtrahend[0]);

    assign borrow_chain[0] = generate_borrow[0] | (propagate_borrow[0] & borrow_in);

    assign generate_borrow[1] = (~minuend[1]) & subtrahend[1];
    assign propagate_borrow[1] = ~(minuend[1] ^ subtrahend[1]);
    assign borrow_chain[1] = generate_borrow[1] | (propagate_borrow[1] & borrow_chain[0]);

    assign generate_borrow[2] = (~minuend[2]) & subtrahend[2];
    assign propagate_borrow[2] = ~(minuend[2] ^ subtrahend[2]);
    assign borrow_chain[2] = generate_borrow[2] | (propagate_borrow[2] & borrow_chain[1]);

    assign generate_borrow[3] = (~minuend[3]) & subtrahend[3];
    assign propagate_borrow[3] = ~(minuend[3] ^ subtrahend[3]);
    assign borrow_chain[3] = generate_borrow[3] | (propagate_borrow[3] & borrow_chain[2]);

    assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow_in;
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow_chain[0];
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow_chain[1];
    assign difference[3] = minuend[3] ^ subtrahend[3] ^ borrow_chain[2];

    assign borrow_out = borrow_chain[3];
endmodule