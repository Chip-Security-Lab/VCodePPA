//SystemVerilog
module parity_corrector (
    input  [7:0] data_in,
    output reg [7:0] data_out,
    output reg error
);
    reg [7:0] parity_lut [0:255];

    reg parity_bit;

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            parity_lut[i] = ^i;
        end
    end

    always @(*) begin
        parity_bit = parity_lut[data_in];
        error = parity_bit;
        if (error)
            data_out = 8'h00;
        else
            data_out = data_in;
    end
endmodule