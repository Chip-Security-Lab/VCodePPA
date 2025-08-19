module xor_async_rst(
    input clk, rst_n,
    input a, b,
    output reg y
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) y <= 0;
        else y <= a ^ b;
    end
endmodule