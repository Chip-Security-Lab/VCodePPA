//SystemVerilog
module therm2bin #(
    parameter THERM_WIDTH = 7,
    parameter BIN_WIDTH = 3 // $clog2(THERM_WIDTH+1) = 3 for 7 bits
) (
    input wire [THERM_WIDTH-1:0] therm_in,
    output reg [BIN_WIDTH-1:0] bin_out
);

    wire [THERM_WIDTH-1:0] p; // propagate signals
    wire [THERM_WIDTH-1:0] g; // generate signals
    wire [THERM_WIDTH:0] carry; // carry chain

    // Assign generate and propagate
    assign p = therm_in;
    assign g = therm_in;

    // Carry chain for 7-bit carry-lookahead adder
    assign carry[0] = 1'b0;
    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry[0]);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carry[0]);
    assign carry[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & carry[0]);
    assign carry[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & carry[0]);
    assign carry[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & carry[0]);

    wire [THERM_WIDTH-1:0] sum_bits;
    assign sum_bits[0] = p[0] ^ carry[0];
    assign sum_bits[1] = p[1] ^ carry[1];
    assign sum_bits[2] = p[2] ^ carry[2];
    assign sum_bits[3] = p[3] ^ carry[3];
    assign sum_bits[4] = p[4] ^ carry[4];
    assign sum_bits[5] = p[5] ^ carry[5];
    assign sum_bits[6] = p[6] ^ carry[6];

    always @(*) begin
        bin_out = sum_bits[0] + sum_bits[1] + sum_bits[2] + sum_bits[3] + sum_bits[4] + sum_bits[5] + sum_bits[6];
    end

endmodule