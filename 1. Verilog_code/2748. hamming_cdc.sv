module hamming_cdc(
    input clk_in, clk_out, rst_n,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);
    reg [3:0] data_sync1, data_sync2;
    reg [6:0] encoded;
    
    // Input clock domain
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) encoded <= 7'b0;
        else begin
            encoded[0] <= data_in[0] ^ data_in[1] ^ data_in[3];
            encoded[1] <= data_in[0] ^ data_in[2] ^ data_in[3];
            encoded[2] <= data_in[0];
            encoded[3] <= data_in[1] ^ data_in[2] ^ data_in[3];
            encoded[4] <= data_in[1];
            encoded[5] <= data_in[2];
            encoded[6] <= data_in[3];
        end
    end
    
    // Clock domain crossing
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out <= 7'b0;
        end else begin
            encoded_out <= encoded;
        end
    end
endmodule