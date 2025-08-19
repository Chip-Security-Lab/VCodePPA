module rng_lcg_4(
    input              clk,
    input              rst,
    input              en,
    output reg [31:0]  rand_val
);
    parameter A = 32'h41C64E6D;
    parameter C = 32'h00003039;
    always @(posedge clk) begin
        if(rst)      rand_val <= 32'h12345678;
        else if(en)  rand_val <= rand_val * A + C;
    end
endmodule