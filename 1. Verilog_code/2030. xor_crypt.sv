module xor_crypt #(parameter KEY=8'hA5) (
    input [7:0] data_in,
    output [7:0] data_out
);
    assign data_out = data_in ^ KEY;
endmodule