module parity_decoder(
    input [2:0] addr,
    input parity_bit,
    output reg [7:0] select,
    output reg parity_error
);
    wire expected_parity;
    assign expected_parity = ^addr; // XOR of all bits

    always @(*) begin
        parity_error = (expected_parity != parity_bit);
        select = parity_error ? 8'b0 : (8'b1 << addr);
    end
endmodule