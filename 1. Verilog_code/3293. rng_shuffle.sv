module rng_shuffle_13(
    input             clk,
    input             rst,
    input             en,
    output reg [7:0]  rand_o
);
    always @(posedge clk) begin
        if(rst)    rand_o <= 8'hC3;
        else if(en)begin
            rand_o <= {rand_o[3:0], rand_o[7:4]} ^ {4'h9, 4'h6};
        end
    end
endmodule