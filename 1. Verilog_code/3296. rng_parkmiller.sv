module rng_parkmiller_16(
    input             clk,
    input             rst,
    input             en,
    output reg [31:0] rand_out
);
    always @(posedge clk) begin
        if(rst) rand_out <= 32'd1;
        else if(en) rand_out <= (rand_out * 32'd16807) % 32'd2147483647;
    end
endmodule