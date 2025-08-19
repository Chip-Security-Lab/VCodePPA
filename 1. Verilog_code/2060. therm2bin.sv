module therm2bin #(parameter THERM_WIDTH = 7, BIN_WIDTH = $clog2(THERM_WIDTH+1)) (
    input wire [THERM_WIDTH-1:0] therm_in,
    output reg [BIN_WIDTH-1:0] bin_out
);
    integer i;
    always @(*) begin
        bin_out = {BIN_WIDTH{1'b0}};
        for (i = 0; i < THERM_WIDTH; i = i + 1)
            bin_out = bin_out + therm_in[i];
    end
endmodule
