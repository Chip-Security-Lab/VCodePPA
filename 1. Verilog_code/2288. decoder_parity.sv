module decoder_parity (
    input [4:0] addr_in,  // [4]=parity
    output reg valid,
    output [7:0] decoded
);
    wire parity = ^addr_in[3:0];
    assign decoded = valid ? (1'b1 << addr_in[3:0]) : 8'h0;
    always @(*) valid = (parity == addr_in[4]);
endmodule