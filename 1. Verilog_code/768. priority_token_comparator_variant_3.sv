//SystemVerilog
module token_match_unit #(
    parameter TOKEN_WIDTH = 8
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] compare_token,
    input valid,
    output reg match
);
    always @(*) begin
        match = valid && (input_token == compare_token);
    end
endmodule

module priority_encoder #(
    parameter NUM_INPUTS = 4
)(
    input [NUM_INPUTS-1:0] match_signals,
    output reg match_found,
    output reg [1:0] match_index
);
    always @(*) begin
        casez(match_signals)
            4'b1???: begin match_found = 1'b1; match_index = 2'd0; end
            4'b01??: begin match_found = 1'b1; match_index = 2'd1; end
            4'b001?: begin match_found = 1'b1; match_index = 2'd2; end
            4'b0001: begin match_found = 1'b1; match_index = 2'd3; end
            default: begin match_found = 1'b0; match_index = 2'd0; end
        endcase
    end
endmodule

module priority_token_comparator #(
    parameter TOKEN_WIDTH = 8,
    parameter NUM_TOKENS = 4
)(
    input [TOKEN_WIDTH-1:0] input_token,
    input [TOKEN_WIDTH-1:0] token_array [0:NUM_TOKENS-1],
    input [NUM_TOKENS-1:0] token_valid,
    output reg match_found,
    output reg [1:0] match_index,
    output reg [NUM_TOKENS-1:0] match_bitmap
);

    wire [NUM_TOKENS-1:0] match_signals;

    genvar i;
    generate
        for (i = 0; i < NUM_TOKENS; i = i + 1) begin : match_units
            token_match_unit #(
                .TOKEN_WIDTH(TOKEN_WIDTH)
            ) match_unit_inst (
                .input_token(input_token),
                .compare_token(token_array[i]),
                .valid(token_valid[i]),
                .match(match_signals[i])
            );
        end
    endgenerate

    priority_encoder #(
        .NUM_INPUTS(NUM_TOKENS)
    ) encoder_inst (
        .match_signals(match_signals),
        .match_found(match_found),
        .match_index(match_index)
    );

    always @(*) begin
        match_bitmap = match_signals;
    end

endmodule