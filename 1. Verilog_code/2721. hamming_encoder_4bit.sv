module hamming_encoder_4bit(
    input clk, rst_n,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) encoded_out <= 7'b0;
        else begin
            encoded_out[0] = data_in[0] ^ data_in[1] ^ data_in[3];
            encoded_out[1] = data_in[0] ^ data_in[2] ^ data_in[3];
            encoded_out[2] = data_in[0];
            encoded_out[3] = data_in[1] ^ data_in[2] ^ data_in[3];
            encoded_out[4] = data_in[1];
            encoded_out[5] = data_in[2];
            encoded_out[6] = data_in[3];
        end
    end
endmodule