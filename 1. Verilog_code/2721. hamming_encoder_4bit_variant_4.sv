//SystemVerilog
module hamming_encoder_4bit(
    input clk, rst_n,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);
    // Buffered input data registers to reduce fan-out
    reg [3:0] data_in_buf1, data_in_buf2;
    // Intermediate calculation registers
    reg p1, p2, p4; // Parity bits
    
    // First pipeline stage: buffer the input data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_buf1 <= 4'b0;
            data_in_buf2 <= 4'b0;
        end else begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in;
        end
    end
    
    // Second pipeline stage: calculate parity bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p1 <= 1'b0;
            p2 <= 1'b0;
            p4 <= 1'b0;
        end else begin
            p1 <= data_in_buf1[0] ^ data_in_buf1[1] ^ data_in_buf1[3];
            p2 <= data_in_buf1[0] ^ data_in_buf1[2] ^ data_in_buf1[3];
            p4 <= data_in_buf1[1] ^ data_in_buf1[2] ^ data_in_buf1[3];
        end
    end
    
    // Final stage: assemble the encoded output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
        end else begin
            encoded_out[0] <= p1;
            encoded_out[1] <= p2;
            encoded_out[2] <= data_in_buf2[0];
            encoded_out[3] <= p4;
            encoded_out[4] <= data_in_buf2[1];
            encoded_out[5] <= data_in_buf2[2];
            encoded_out[6] <= data_in_buf2[3];
        end
    end
endmodule