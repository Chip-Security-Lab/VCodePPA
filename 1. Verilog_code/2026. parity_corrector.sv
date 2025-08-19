module parity_corrector (
    input [7:0] data_in,
    output [7:0] data_out,
    output error
);
    wire parity = ^data_in;
    assign error = parity;
    assign data_out = error ? 8'h00 : data_in;
endmodule