//SystemVerilog
module hamming_decoder (
    input wire [6:0] hamming_in,
    output reg [3:0] data_out,
    output reg error_detected
);

    // LUT for syndrome calculation: index is hamming_in[6:0], value is syndrome[2:0]
    reg [2:0] syndrome_lut [0:127];
    // LUT for error detection: index is syndrome[2:0], value is error_detected
    reg error_lut [0:7];
    // LUT for data extraction: index is hamming_in[6:0], value is data_out[3:0]
    reg [3:0] data_lut [0:127];

    reg [2:0] syndrome_reg;
    reg [3:0] data_reg;
    reg error_reg;

    integer i;

    // LUT initialization
    initial begin
        // Syndrome LUT
        for (i = 0; i < 128; i = i + 1) begin
            syndrome_lut[i][0] = i[0] ^ i[2] ^ i[4] ^ i[6];
            syndrome_lut[i][1] = i[1] ^ i[2] ^ i[5] ^ i[6];
            syndrome_lut[i][2] = i[3] ^ i[4] ^ i[5] ^ i[6];
            data_lut[i] = {i[6], i[5], i[4], i[2]};
        end
        // Error LUT
        for (i = 0; i < 8; i = i + 1) begin
            error_lut[i] = |i[2:0];
        end
    end

    always @(*) begin
        syndrome_reg = syndrome_lut[hamming_in];
        error_reg = error_lut[syndrome_reg];
        data_reg = data_lut[hamming_in];
    end

    always @(*) begin
        data_out = data_reg;
        error_detected = error_reg;
    end

endmodule