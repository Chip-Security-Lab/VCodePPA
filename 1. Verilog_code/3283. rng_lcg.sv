module rng_lcg_3(
    input            clk,
    input            en,
    output reg [7:0] rnd
);
    parameter MULT = 8'd5;
    parameter INC  = 8'd1;
    initial rnd = 8'd7;
    always @(posedge clk) begin
        if(en) rnd <= (rnd * MULT + INC);
    end
endmodule