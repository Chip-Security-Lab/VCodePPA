//SystemVerilog
module therm2bin #(parameter THERM_WIDTH = 7, BIN_WIDTH = 3) (
    input wire [THERM_WIDTH-1:0] therm_in,
    output reg [BIN_WIDTH-1:0] bin_out
);
    wire bit2, bit1, bit0;

    // bit2: High if at least 4 or more bits are set (therm_in[3] or higher)
    assign bit2 = therm_in[4] | therm_in[5] | therm_in[6];

    // bit1: High if the count of ones modulo 4 is 2 or 3 (i.e., bits [2], [3], [6], [7])
    assign bit1 = (therm_in[2] & ~therm_in[4] & ~therm_in[5] & ~therm_in[6]) |
                  (therm_in[3] & ~therm_in[5] & ~therm_in[6]) |
                  (therm_in[4] & therm_in[5] & ~therm_in[6]) |
                  (therm_in[6]);

    // bit0: High if the input has an odd number of ones (parity)
    assign bit0 = therm_in[0] ^ therm_in[1] ^ therm_in[2] ^ therm_in[3] ^ therm_in[4] ^ therm_in[5] ^ therm_in[6];

    always @(*) begin
        bin_out = {bit2, bit1, bit0};
    end
endmodule