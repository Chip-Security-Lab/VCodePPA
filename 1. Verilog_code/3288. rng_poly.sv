module rng_poly_8(
    input                 clk,
    input                 en,
    output reg [11:0]     r_out
);
    initial r_out = 12'hABC;
    wire fb = r_out[11] ^ r_out[9] ^ r_out[6] ^ r_out[3];
    always @(posedge clk) begin
        if(en) r_out <= {r_out[10:0], fb};
    end
endmodule