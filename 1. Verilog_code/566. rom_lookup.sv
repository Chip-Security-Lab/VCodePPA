module rom_lookup #(parameter N=4)(
    input [N-1:0] x,
    output reg [2**N-1:0] y
);
    always @(*) begin
        y = 1 << x; // One-hot output
    end
endmodule