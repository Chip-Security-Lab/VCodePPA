module rng_shiftxor_6(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rnd
);
    reg [7:0] tmp_reg;
    wire mix = ^(tmp_reg[7:4]); 
    always @(posedge clk) begin
        if(rst)     tmp_reg <= 8'hF0;
        else if(en) tmp_reg <= {tmp_reg[6:0], mix};
    end
    always @(*) rnd = tmp_reg;
endmodule