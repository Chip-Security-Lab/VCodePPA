//SystemVerilog
module hamming_cdc(
    input clk_in, clk_out, rst_n,
    input [3:0] data_in,
    output reg [6:0] encoded_out
);

    reg [6:0] encoded;
    reg [6:0] encoded_sync;
    wire [2:0] parity_bits;
    wire [3:0] data_bits;

    // Parity bit generation
    assign parity_bits = {
        data_in[0],
        data_in[0] ^ data_in[2] ^ data_in[3],
        data_in[0] ^ data_in[1] ^ data_in[3]
    };

    // Data bit assignment
    assign data_bits = {
        data_in[3],
        data_in[2],
        data_in[1],
        data_in[1] ^ data_in[2] ^ data_in[3]
    };

    // Input clock domain - parity bits
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            encoded[2:0] <= 3'b0;
        else
            encoded[2:0] <= parity_bits;
    end

    // Input clock domain - data bits
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            encoded[6:3] <= 4'b0;
        else
            encoded[6:3] <= data_bits;
    end

    // First stage synchronization
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            encoded_sync <= 7'b0;
        else
            encoded_sync <= encoded;
    end

    // Second stage synchronization and output
    always @(posedge clk_out or negedge rst_n) begin
        if (!rst_n)
            encoded_out <= 7'b0;
        else
            encoded_out <= encoded_sync;
    end

endmodule