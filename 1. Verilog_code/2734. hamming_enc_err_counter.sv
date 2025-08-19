module hamming_enc_err_counter(
    input clk, rst, en,
    input [3:0] data_in,
    input error_inject,
    output reg [6:0] encoded,
    output reg [7:0] error_count
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            error_count <= 8'b0;
        end else if (en) begin
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
            
            if (error_inject) begin
                encoded[0] <= ~(data_in[0] ^ data_in[1] ^ data_in[3]);
                error_count <= error_count + 1;
            end
        end
    end
endmodule