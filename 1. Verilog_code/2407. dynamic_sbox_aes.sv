module dynamic_sbox_aes (
    input clk, gen_sbox,
    input [7:0] sbox_in,
    output reg [7:0] sbox_out
);
    reg [7:0] sbox [0:255];
    integer i;
    
    always @(posedge clk) begin
        if (gen_sbox) begin
            for(i=0; i<256; i=i+1)
                sbox[i] = (i * 8'h1B) ^ 8'h63;
        end
        sbox_out <= sbox[sbox_in];
    end
endmodule
