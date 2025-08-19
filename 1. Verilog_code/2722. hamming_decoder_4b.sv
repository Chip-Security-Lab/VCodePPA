module hamming_decoder_4b(
    input clock, reset,
    input [6:0] code_in,
    output reg [3:0] data_out,
    output reg error_detected
);
    reg [2:0] syndrome;
    always @(posedge clock) begin
        if (reset) begin
            data_out <= 4'b0; error_detected <= 1'b0;
        end else begin
            syndrome[0] = code_in[0] ^ code_in[2] ^ code_in[4] ^ code_in[6];
            syndrome[1] = code_in[1] ^ code_in[2] ^ code_in[5] ^ code_in[6];
            syndrome[2] = code_in[3] ^ code_in[4] ^ code_in[5] ^ code_in[6];
            error_detected = |syndrome;
            data_out = {code_in[6], code_in[5], code_in[4], code_in[2]};
        end
    end
endmodule