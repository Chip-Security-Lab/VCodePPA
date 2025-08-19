module hamm_codec(
    input t_clk, t_rst,
    input [3:0] i_data,
    input i_encode_n_decode,
    output reg [6:0] o_encoded,
    output reg [3:0] o_decoded,
    output reg o_error
);
    reg [2:0] r_syndrome;
    
    always @(posedge t_clk or posedge t_rst) begin
        if (t_rst) begin
            o_encoded <= 7'b0;
            o_decoded <= 4'b0;
            o_error <= 1'b0;
            r_syndrome <= 3'b0;
        end else if (i_encode_n_decode) begin
            // Encode operation
            o_encoded[0] <= i_data[0] ^ i_data[1] ^ i_data[3];
            o_encoded[1] <= i_data[0] ^ i_data[2] ^ i_data[3];
            o_encoded[2] <= i_data[0];
            o_encoded[3] <= i_data[1] ^ i_data[2] ^ i_data[3];
            o_encoded[4] <= i_data[1];
            o_encoded[5] <= i_data[2];
            o_encoded[6] <= i_data[3];
        end else begin
            // Decode operation
            r_syndrome[0] <= o_encoded[0] ^ o_encoded[2] ^ o_encoded[4] ^ o_encoded[6];
            r_syndrome[1] <= o_encoded[1] ^ o_encoded[2] ^ o_encoded[5] ^ o_encoded[6];
            r_syndrome[2] <= o_encoded[3] ^ o_encoded[4] ^ o_encoded[5] ^ o_encoded[6];
            o_error <= |r_syndrome;
            o_decoded <= {o_encoded[6], o_encoded[5], o_encoded[4], o_encoded[2]};
        end
    end
endmodule