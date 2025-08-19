//SystemVerilog
module active_low_decoder(
    input [2:0] address,
    output reg [7:0] decode_n
);
    always @(*) begin
        // Direct implementation using address bits
        // This eliminates the intermediate partial_decode register
        // and simplifies the logic by directly computing the active-low outputs
        decode_n[0] = address[0] | address[1] | address[2];
        decode_n[1] = ~address[0] | address[1] | address[2];
        decode_n[2] = address[0] | ~address[1] | address[2];
        decode_n[3] = ~address[0] | ~address[1] | address[2];
        decode_n[4] = address[0] | address[1] | ~address[2];
        decode_n[5] = ~address[0] | address[1] | ~address[2];
        decode_n[6] = address[0] | ~address[1] | ~address[2];
        decode_n[7] = ~address[0] | ~address[1] | ~address[2];
    end
endmodule