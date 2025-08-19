module hamming_16bit_enc_en(
    input clock, enable, clear,
    input [15:0] data_in,
    output reg [20:0] ham_out
);
    always @(posedge clock) begin
        if (clear) ham_out <= 21'b0;
        else if (enable) begin
            // Calculate parity bits (simplified)
            ham_out[0] <= ^(data_in & 16'b1010_1010_1010_1010);
            ham_out[1] <= ^(data_in & 16'b1100_1100_1100_1100);
            ham_out[3] <= ^(data_in & 16'b1111_0000_1111_0000);
            ham_out[7] <= ^(data_in & 16'b1111_1111_0000_0000);
            ham_out[15] <= ^(data_in & 16'b1111_1111_1111_1111);
            // Insert data bits (simplified implementation)
            ham_out[20:16] <= data_in[15:11];
            ham_out[14:8] <= data_in[10:4]; 
            ham_out[6:4] <= data_in[3:1];
            ham_out[2] <= data_in[0];
        end
    end
endmodule