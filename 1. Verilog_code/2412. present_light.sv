module present_light (
    input clk, enc_dec,
    input [63:0] plaintext,
    output reg [63:0] ciphertext
);
    reg [79:0] key_reg;
    always @(posedge clk) begin
        key_reg <= {key_reg[18:0], key_reg[79:76]};
        ciphertext <= plaintext ^ key_reg[63:0];
        // Simplified sBoxLayer and pLayer omitted
    end
endmodule
