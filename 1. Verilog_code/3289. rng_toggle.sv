module rng_toggle_9(
    input            clk,
    input            rst,
    output reg [7:0] rand_val
);
    always @(posedge clk) begin
        if(rst) rand_val <= 8'h55;
        else    rand_val <= rand_val ^ 8'b00000001;
    end
endmodule
