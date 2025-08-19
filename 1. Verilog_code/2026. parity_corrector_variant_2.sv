//SystemVerilog
module parity_corrector (
    input  [7:0] data_in,
    output reg [7:0] data_out,
    output reg error
);
    wire parity_bit;

    assign parity_bit = data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];

    always @(*) begin
        error = parity_bit;
        data_out = error ? 8'h00 : data_in;
    end
endmodule